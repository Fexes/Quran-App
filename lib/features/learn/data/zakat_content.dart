import '../domain/learning_guide.dart';

const zakatGuide = LearningGuide(
  id: 'zakat',
  title: 'Zakat',
  description: 'Check what you own, calculate, and give with care.',
  coverImage: 'assets/images/learn/zakat.webp',
  coverDescription: 'Hands offering a discreet gift of charity.',
  chapters: [
    GuideChapter(
      id: 'zakat-check',
      title: 'Check when it is due',
      subtitle: 'Nisab and your lunar year',
      image: 'assets/images/learn/zakat_assess.webp',
      imageDescription:
          'Gold and silver coins, a bangle, and a notebook for assessing wealth.',
      readMinutes: 2,
      category: 'Before calculating',
      introduction:
          'This is a simple guide to zakat on an adult’s cash, precious metals, and trade wealth. Crops, livestock, complex investments, and children’s wealth have additional rules.',
      steps: [
        GuideGuidance(
          'Identify your nisab',
          'Nisab is the minimum wealth threshold. A common Hanafi convention values 87.48 g of gold or 612.36 g of silver. Other authorities use different weight conventions, such as 85 g of gold. Use one recognized method consistently.',
        ),
        GuideGuidance(
          'Choose the applicable standard',
          'For mixed cash and trade wealth, many Hanafi advisers use the silver threshold. Other scholars recommend gold. Confirm the method with your trusted zakat adviser and use its current value on your calculation date.',
        ),
        GuideGuidance(
          'Track the hawl',
          'Record when your eligible wealth first reaches nisab. Assess it after a lunar year, then on that annual date. Schools differ over drops below nisab and newly acquired money; do not assume each coin needs its own year.',
        ),
      ],
      sourceIds: ['zakat-nisab', 'zakat-hanafi', 'zakat-hawl'],
    ),
    GuideChapter(
      id: 'zakat-calculate',
      title: 'Calculate the amount',
      subtitle: 'Eligible wealth × 2.5%',
      image: 'assets/images/learn/zakat_calculate.webp',
      imageDescription:
          'A calculator, ledger, coins and envelopes for preparing a zakat calculation.',
      readMinutes: 2,
      category: 'Your annual calculation',
      introduction:
          'For the money and trade wealth covered here, the lunar-year rate is one fortieth, or 2.5%, of the qualifying total, not just the amount above nisab.',
      steps: [
        GuideGuidance(
          'Add the eligible assets',
          'Include cash, account balances, zakatable gold and silver, trade stock held for sale, and recoverable money owed to you. Value them appropriately on the due date. Your home, ordinary personal car, clothes, and household belongings are generally excluded unless held as trade stock.',
        ),
        GuideGuidance(
          'Check deductions',
          'Debt deductions differ by school. Under a common Hanafi approach, deduct qualifying immediate debts and eligible instalments, not automatically an entire long-term mortgage. Future living costs are not a blanket deduction.',
        ),
        GuideGuidance(
          'Apply the rate',
          'Example in any one currency: eligible assets 12,000 minus allowable debts 2,000 = net wealth 10,000. If nisab and hawl are satisfied, 10,000 × 0.025 = 250 due. The numbers are an illustration, not a current nisab value.',
        ),
      ],
      notes: [
        GuideGuidance(
          'Jewellery and investments need care',
          'Hanafi practice includes personal gold and silver jewellery; other schools exempt some lawful personal-use jewellery. Pensions, shares, business debts, and inaccessible assets need a tailored calculation.',
        ),
      ],
      sourceIds: [
        'zakat-rate',
        'zakat-hanafi',
        'zakat-debt',
        'zakat-hawl',
        'zakat-nisab',
      ],
    ),
    GuideChapter(
      id: 'zakat-pay',
      title: 'Give it correctly',
      subtitle: 'Intention and eligible recipients',
      image: 'assets/images/learn/zakat.webp',
      imageDescription:
          'Charity offered discreetly from one person to another.',
      readMinutes: 2,
      category: 'Complete the payment',
      introduction:
          'Zakat has defined recipients. A worthwhile donation is not automatically a valid zakat payment.',
      steps: [
        GuideGuidance(
          'Intend zakat',
          'Intend the payment as your obligatory zakat when setting it aside or giving it. Pay promptly when due and keep a record of the calculation and payment.',
        ),
        GuideGuidance(
          'Choose eligible recipients',
          'Quran 9:60 identifies eight categories, including the poor, the needy, eligible debtors, and stranded travellers. The other categories have detailed rules. Ask before treating a general building project or any charitable cause as zakat.',
        ),
        GuideGuidance(
          'Give directly or use a trusted agent',
          'Confirm the recipient’s eligibility or choose an organization with a clear zakat policy. Giving to relatives can be valuable, but dependants, parents, children, and spouses have specific restrictions and differences between schools.',
        ),
      ],
      notes: [
        GuideGuidance(
          'Zakat al-fitr is separate',
          'Zakat al-fitr is the Ramadan-end payment associated with people in a household, not this annual 2.5% wealth calculation. Arrange it before the Eid prayer, using qualified local guidance for the amount, food or money method, and whom you must pay for.',
        ),
      ],
      sourceIds: [
        'zakat-recipients',
        'zakat-nisab',
        'zakat-fitr',
        'zakat-intention',
        'zakat-family',
      ],
    ),
  ],
  sources: [
    GuideSource(
      id: 'zakat-nisab',
      title: 'Nisab and common questions',
      subtitle: 'Islamic Relief Worldwide, Zakat FAQ',
      url: 'https://islamic-relief.org/zakat-faq/',
    ),
    GuideSource(
      id: 'zakat-hanafi',
      title: 'Assets and the Hanafi calculation',
      subtitle: 'SeekersGuidance zakat calculator and guidance',
      url: 'https://seekersguidance.org/zakatcalculator/',
    ),
    GuideSource(
      id: 'zakat-hawl',
      title: 'The lunar year and assessment',
      subtitle: 'Egypt’s Dar Al-Ifta, fatwa 7746',
      url:
          'https://www.dar-alifta.org/en/fatwa/details/7746/zakah-on-collected-and-uncollected-debts',
    ),
    GuideSource(
      id: 'zakat-rate',
      title: 'One fortieth on silver',
      subtitle: 'Sahih al-Bukhari 1454',
      url: 'https://sunnah.com/bukhari:1454',
    ),
    GuideSource(
      id: 'zakat-debt',
      title: 'Debt deductions',
      subtitle: 'Faraz A. Khan, SeekersGuidance, Hanafi answer',
      url:
          'https://seekersguidance.org/answers/hanafi-fiqh/paying-zakat-vs-paying-off-a-debt/',
    ),
    GuideSource(
      id: 'zakat-recipients',
      title: 'The categories of recipients',
      subtitle: 'Quran 9:60',
      url: 'https://quran.com/9/60',
    ),
    GuideSource(
      id: 'zakat-intention',
      title: 'Intending the payment as zakat',
      subtitle: 'Muhammad Sayyid Tantawi, Egypt’s Dar Al-Ifta',
      url:
          'https://dar-alifta.org/en/fatwa/details/23927/the-importance-of-forming-the-intention-at-the-time-of-paying-zakat',
    ),
    GuideSource(
      id: 'zakat-family',
      title: 'Relatives and maintenance duties',
      subtitle: 'Egypt’s Dar Al-Ifta, Fatwa Council',
      url:
          'https://www.dar-alifta.org/en/fatwa/details/21918/covering-granddaughter%E2%80%99s-marriage-expenses-from-zakat-money',
    ),
    GuideSource(
      id: 'zakat-fitr',
      title: 'The separate Eid payment',
      subtitle: 'Sahih al-Bukhari 1503',
      url: 'https://sunnah.com/bukhari:1503',
    ),
  ],
  questions: [
    GuideGuidance(
      'Is zakat only paid in Ramadan?',
      'No. Pay when your zakat becomes due. Ramadan can be a convenient annual reminder if it matches the rules for your due date; it does not erase an earlier obligation.',
    ),
    GuideGuidance(
      'Is it 2.5% of my salary?',
      'Not automatically. This calculation concerns the zakatable wealth you own when due. Income, savings, investments, and debts must be classified before applying the rate.',
    ),
  ],
);
