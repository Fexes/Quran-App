"""Lossless float32 vector storage shared by the builder and host tooling."""

from __future__ import annotations

import sqlite3
from collections.abc import Iterator


VECTOR_BYTES = 384 * 4
VECTOR_BLOCK_SIZE = 128
VECTOR_STORAGE = "blocks_v1"

PACKED_VECTOR_SCHEMA = f"""
CREATE TABLE vector_blocks(
 id INTEGER PRIMARY KEY,
 embeddings BLOB NOT NULL CHECK(length(embeddings)>0 AND length(embeddings)%{VECTOR_BYTES}=0)
);
CREATE TABLE vector_entries(
 id INTEGER PRIMARY KEY, passage_id INTEGER NOT NULL REFERENCES passages(id),
 language TEXT NOT NULL, chunk_index INTEGER NOT NULL,
 block_id INTEGER NOT NULL REFERENCES vector_blocks(id),
 byte_offset INTEGER NOT NULL CHECK(byte_offset>=0 AND byte_offset%{VECTOR_BYTES}=0)
);
CREATE INDEX vectors_passage_id ON vector_entries(passage_id);
CREATE VIEW vectors AS
 SELECT v.*, substr(b.embeddings,v.byte_offset+1,{VECTOR_BYTES}) AS embedding
 FROM vector_entries v JOIN vector_blocks b ON b.id=v.block_id;
"""


class PackedVectorWriter:
    """Pack exact embedding bytes without changing vector IDs or ordering."""

    def __init__(self, connection: sqlite3.Connection):
        self.connection = connection
        self.block_id = 1
        self.next_id = 1
        self.entries = []
        self.embeddings = bytearray()

    def append(self, passage_id: int, language: str, chunk_index: int,
               embedding: bytes, *, vector_id: int | None = None) -> None:
        if len(embedding) != VECTOR_BYTES:
            raise ValueError(f"Expected {VECTOR_BYTES}-byte float32 embedding")
        if vector_id is None:
            vector_id = self.next_id
        elif vector_id < self.next_id:
            raise ValueError("Packed vector IDs must be strictly increasing")
        self.entries.append((vector_id, passage_id, language, chunk_index,
                             self.block_id, len(self.embeddings)))
        self.embeddings.extend(embedding)
        self.next_id = vector_id + 1
        if len(self.entries) == VECTOR_BLOCK_SIZE:
            self.flush()

    def flush(self) -> None:
        if not self.entries:
            return
        self.connection.execute("INSERT INTO vector_blocks(id,embeddings) VALUES(?,?)",
                                (self.block_id, bytes(self.embeddings)))
        self.connection.executemany(
            "INSERT INTO vector_entries(id,passage_id,language,chunk_index,block_id,byte_offset) VALUES(?,?,?,?,?,?)",
            self.entries,
        )
        self.block_id += 1
        self.entries.clear()
        self.embeddings.clear()


def iter_vectors(connection: sqlite3.Connection, passage_id: int | None = None
                 ) -> Iterator[tuple[int, int, str, int, bytes]]:
    """Read legacy row BLOBs and packed BLOBs through the same byte contract."""
    metadata = dict(connection.execute("SELECT key,value FROM metadata"))
    where = " WHERE passage_id=?" if passage_id is not None else ""
    parameters = (passage_id,) if passage_id is not None else ()
    if metadata.get("vector_storage") != VECTOR_STORAGE:
        yield from connection.execute(
            "SELECT id,passage_id,language,chunk_index,embedding FROM vectors" + where + " ORDER BY id",
            parameters,
        )
        return
    previous_block = None
    embeddings = b""
    for vector_id, owner_id, language, chunk_index, block_id, offset in connection.execute(
        "SELECT id,passage_id,language,chunk_index,block_id,byte_offset FROM vector_entries" + where + " ORDER BY id",
        parameters,
    ):
        if block_id != previous_block:
            block = connection.execute("SELECT embeddings FROM vector_blocks WHERE id=?", (block_id,)).fetchone()
            if block is None:
                raise ValueError(f"Vector {vector_id} references missing block {block_id}")
            embeddings = block[0]
            previous_block = block_id
        if offset < 0 or offset % VECTOR_BYTES or offset + VECTOR_BYTES > len(embeddings):
            raise ValueError(f"Vector {vector_id} has an invalid packed offset")
        yield vector_id, owner_id, language, chunk_index, embeddings[offset:offset + VECTOR_BYTES]
