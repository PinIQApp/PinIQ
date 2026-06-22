class OperatorProduct {
  const OperatorProduct({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.margin,
    required this.status,
    required this.cadence,
    required this.vendor,
    required this.source,
    required this.summary,
    required this.bullets,
  });

  final String id;
  final String name;
  final String category;
  final String price;
  final String margin;
  final String status;
  final String cadence;
  final String vendor;
  final String source;
  final String summary;
  final List<String> bullets;

  OperatorProduct copyWith({
    String? id,
    String? name,
    String? category,
    String? price,
    String? margin,
    String? status,
    String? cadence,
    String? vendor,
    String? source,
    String? summary,
    List<String>? bullets,
  }) {
    return OperatorProduct(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      margin: margin ?? this.margin,
      status: status ?? this.status,
      cadence: cadence ?? this.cadence,
      vendor: vendor ?? this.vendor,
      source: source ?? this.source,
      summary: summary ?? this.summary,
      bullets: bullets ?? this.bullets,
    );
  }
}

class OperatorSubscriptionPlan {
  const OperatorSubscriptionPlan({
    required this.id,
    required this.title,
    required this.cadence,
    required this.price,
    required this.billingCode,
    required this.access,
    required this.note,
    required this.bullets,
  });

  final String id;
  final String title;
  final String cadence;
  final String price;
  final String billingCode;
  final String access;
  final String note;
  final List<String> bullets;

  OperatorSubscriptionPlan copyWith({
    String? id,
    String? title,
    String? cadence,
    String? price,
    String? billingCode,
    String? access,
    String? note,
    List<String>? bullets,
  }) {
    return OperatorSubscriptionPlan(
      id: id ?? this.id,
      title: title ?? this.title,
      cadence: cadence ?? this.cadence,
      price: price ?? this.price,
      billingCode: billingCode ?? this.billingCode,
      access: access ?? this.access,
      note: note ?? this.note,
      bullets: bullets ?? this.bullets,
    );
  }
}

class OperatorVendor {
  const OperatorVendor({
    required this.id,
    required this.name,
    required this.lane,
    required this.status,
    required this.marginNote,
    required this.summary,
    required this.notes,
  });

  final String id;
  final String name;
  final String lane;
  final String status;
  final String marginNote;
  final String summary;
  final List<String> notes;

  OperatorVendor copyWith({
    String? id,
    String? name,
    String? lane,
    String? status,
    String? marginNote,
    String? summary,
    List<String>? notes,
  }) {
    return OperatorVendor(
      id: id ?? this.id,
      name: name ?? this.name,
      lane: lane ?? this.lane,
      status: status ?? this.status,
      marginNote: marginNote ?? this.marginNote,
      summary: summary ?? this.summary,
      notes: notes ?? this.notes,
    );
  }
}

List<OperatorProduct> seedOperatorProducts() {
  return const [
    OperatorProduct(
      id: 'grip-trainer-core',
      name: 'Grip Trainer Core',
      category: 'Performance',
      price: '\$34',
      margin: '\$17',
      status: 'Live',
      cadence: 'entry offer',
      vendor: 'Elite Performance Tools',
      source: 'Direct performance catalog',
      summary:
          'Simple front-end product for stronger hands, wrists, and control on the mat.',
      bullets: [
        'Easy to understand in under 3 seconds',
        'No sizing issues or complicated variants',
        'Perfect flagship offer for short-form content',
      ],
    ),
    OperatorProduct(
      id: 'grip-band-bundle',
      name: 'Grip + Mini Band Bundle',
      category: 'Performance',
      price: '\$58',
      margin: '\$28',
      status: 'Live',
      cadence: 'bundle offer',
      vendor: 'Elite Performance Tools',
      source: 'Performance bundle lane',
      summary:
          'Best first bundle for grip, hand-fighting, activation, and recovery prep.',
      bullets: [
        'Natural cart upgrade from the flagship tool',
        'Great for parents and off-season athletes',
        'Stronger perceived value than a single item',
      ],
    ),
    OperatorProduct(
      id: 'recovery-band-kit',
      name: 'Recovery + Stretch Band Kit',
      category: 'Recovery',
      price: '\$32',
      margin: '\$15',
      status: 'Live',
      cadence: 'cart bump',
      vendor: 'Mobility Wrestling Supply',
      source: 'Recovery lane',
      summary:
          'Stretch and recovery band set built for warmup, cool down, and mat-ready mobility.',
      bullets: [
        'Easy cart add-on from any performance order',
        'Works well in parent-safe offers',
        'Simple demonstration product for short-form content',
      ],
    ),
    OperatorProduct(
      id: 'mat-tape-case',
      name: 'Mat Tape Case',
      category: 'Facility',
      price: '\$84',
      margin: '\$18',
      status: 'Live',
      cadence: 'weekly reorder',
      vendor: 'MatSupply Direct',
      source: 'Dropship catalog',
      summary: 'High-repeat consumable that programs burn through all season.',
      bullets: [
        'Fits everyday dropshipping and replenishment flow',
        'Works well with cleaning supply bundles',
        'Low-friction item for recurring coach orders',
      ],
    ),
    OperatorProduct(
      id: 'mat-cleaning-bundle',
      name: 'Mat Cleaning Bundle',
      category: 'Cleaning',
      price: '\$126',
      margin: '\$29',
      status: 'Live',
      cadence: 'bi-monthly restock',
      vendor: 'CleanMat Pro',
      source: 'Recurring supply vendor',
      summary:
          'Sprayers, concentrate, towels, and refill gear for daily room upkeep.',
      bullets: [
        'Easy operational buy for every wrestling room',
        'Can be positioned as a recurring facilities subscription',
        'Strong fit for school purchasing rather than athlete checkout',
      ],
    ),
    OperatorProduct(
      id: 'score-clock-pro',
      name: 'Score Clock Pro',
      category: 'Equipment',
      price: '\$649',
      margin: '\$96',
      status: 'Live',
      cadence: 'seasonal purchase',
      vendor: 'ScoreTech Athletics',
      source: 'Equipment dropship partner',
      summary:
          'Tournament table clock package for rooms replacing older hardware.',
      bullets: [
        'Higher-ticket operator margin item',
        'Good upsell from team event hosting',
        'Can bundle with scoring display accessories',
      ],
    ),
    OperatorProduct(
      id: 'scoring-tv-display-kit',
      name: 'Scoring TV Display Kit',
      category: 'Tech',
      price: '\$899',
      margin: '\$134',
      status: 'Draft',
      cadence: 'event upgrade',
      vendor: 'BracketVision Displays',
      source: 'AV partner inventory',
      summary:
          'Mounted TV package for scoreboards, brackets, and event streams.',
      bullets: [
        'Strong tournament-hosting upgrade item',
        'Pairs naturally with score clock sales',
        'Needs install and vendor notes in checkout copy',
      ],
    ),
    OperatorProduct(
      id: 'coach-laptop-bundle',
      name: 'Coach Laptop Bundle',
      category: 'Tech',
      price: '\$1,249',
      margin: '\$155',
      status: 'Draft',
      cadence: 'annual replacement',
      vendor: 'CoachOps Hardware',
      source: 'Operator tech bundle',
      summary:
          'Laptop, case, and setup bundle for tournament operations and daily admin.',
      bullets: [
        'Useful admin hardware package for coaches',
        'Can bundle with printer or scoring accessories later',
        'Best sold as operator marketplace inventory, not school branding merch',
      ],
    ),
    OperatorProduct(
      id: 'team-shoe-rotation-pack',
      name: 'Team Shoe Rotation Pack',
      category: 'Shoes',
      price: '\$118',
      margin: '\$21',
      status: 'Live',
      cadence: 'seasonal restock',
      vendor: 'WrestleFootwear Co.',
      source: 'Athlete dropship lane',
      summary:
          'Popular wrestling shoe assortment positioned for families and athletes.',
      bullets: [
        'Easy dropship catalog item',
        'Can run limited school-color features without custom manufacturing',
        'Good parent-facing add-on from athlete onboarding',
      ],
    ),
    OperatorProduct(
      id: 'headgear-knee-pad-set',
      name: 'Headgear + Knee Pad Set',
      category: 'Equipment',
      price: '\$72',
      margin: '\$14',
      status: 'Live',
      cadence: 'monthly reorder',
      vendor: 'Wrestle Gear Supply',
      source: 'Starter pack catalog',
      summary:
          'Practical bundle for new wrestlers, camps, and parent checkout.',
      bullets: [
        'Strong everyday store product',
        'Fits dropship model without custom design work',
        'Can be bundled into starter packs later',
      ],
    ),
    OperatorProduct(
      id: 'wrestler-domination-30',
      name: '30-Day Wrestler Domination',
      category: 'Digital',
      price: '\$24',
      margin: '\$24',
      status: 'Live',
      cadence: 'post-purchase upsell',
      vendor: 'Pin IQ Digital',
      source: 'Digital delivery',
      summary:
          'A digital training plan and challenge system designed as the premium upsell behind the grip offers.',
      bullets: [
        'High-margin digital back-end offer',
        'Easy post-purchase upsell after product checkout',
        'Can grow into challenge or membership later',
      ],
    ),
    OperatorProduct(
      id: 'coach-grip-team-pack',
      name: 'Coach Grip Team Pack',
      category: 'Team Pack',
      price: '\$399',
      margin: '\$154',
      status: 'Draft',
      cadence: 'team offer',
      vendor: 'Elite Performance Tools',
      source: 'B2B coach pack',
      summary:
          'Bulk grip and band pack for coaches building off-season hand-fighting and performance systems.',
      bullets: [
        'Best B2B offer in the performance lane',
        'Fits coach outreach and packet sales',
        'Scales better than one-by-one athlete purchases',
      ],
    ),
  ];
}

List<OperatorSubscriptionPlan> seedOperatorSubscriptionPlans() {
  return const [
    OperatorSubscriptionPlan(
      id: 'wrestletech-annual',
      title: 'Pin IQ Annual',
      cadence: 'Annual',
      price: '\$29/mo',
      billingCode: 'WT-ANNUAL',
      access: 'Billed yearly after a 7-day free trial',
      note:
          'Best value for teams that want the full wrestling operating system at the lowest monthly rate.',
      bullets: [
        '7-day free trial',
        'Roster, messages, nutrition, weights, recruiting, and AI tools',
        'Annual billing keeps the effective monthly price at \$29',
      ],
    ),
    OperatorSubscriptionPlan(
      id: 'wrestletech-monthly',
      title: 'Pin IQ Monthly',
      cadence: 'Monthly',
      price: '\$39/mo',
      billingCode: 'WT-MONTHLY',
      access: 'Month-to-month after a 7-day free trial',
      note:
          'Simple monthly plan for coaches who want to test Pin IQ without an annual commitment.',
      bullets: [
        '7-day free trial',
        'Cancel anytime before the next billing period',
        'Same beta feature set as annual while feedback is collected',
      ],
    ),
    OperatorSubscriptionPlan(
      id: 'wrestletech-school',
      title: 'School / Club',
      cadence: 'Custom',
      price: 'Custom',
      billingCode: 'WT-SCHOOL',
      access: 'Multiple teams, staff seats, onboarding, and support',
      note:
          'For larger clubs and schools that need multiple teams, setup help, or future live text/payment integrations.',
      bullets: [
        'Includes annual-plan tools',
        'Built for multi-team programs',
        'Good fit once beta feedback proves the workflow',
      ],
    ),
  ];
}

List<OperatorVendor> seedOperatorVendors() {
  return const [
    OperatorVendor(
      id: 'elite-performance-tools',
      name: 'Elite Performance Tools',
      lane: 'Grip + performance',
      status: 'Preferred',
      marginNote: '40-55% blended margin range',
      summary:
          'Flagship supplier lane for grip trainers, mini bands, and simple performance tools.',
      notes: [
        'Best first lane for short-form content offers',
        'No sizing headaches compared with apparel',
        'Supports a strong front-end offer ladder',
      ],
    ),
    OperatorVendor(
      id: 'mobility-wrestling-supply',
      name: 'Mobility Wrestling Supply',
      lane: 'Recovery tools',
      status: 'Live',
      marginNote: '28-40% margin range',
      summary:
          'Recovery and stretch tool supplier for cart bumps and performance add-ons.',
      notes: [
        'Great for recovery kits and mini-band offers',
        'Simple shipping and low breakage risk',
        'Fits parent-safe performance products well',
      ],
    ),
    OperatorVendor(
      id: 'matsupply-direct',
      name: 'MatSupply Direct',
      lane: 'Facility consumables',
      status: 'Preferred',
      marginNote: '12-22% margin range',
      summary: 'Primary vendor for mat tape and facility resupply.',
      notes: [
        'Strong for repeat school orders',
        'Reliable shipping cadence for weekly replenishment',
        'Good foundation partner for everyday dropshipping',
      ],
    ),
    OperatorVendor(
      id: 'scoretech-athletics',
      name: 'ScoreTech Athletics',
      lane: 'Score clocks',
      status: 'High ticket',
      marginNote: '14-18% margin range',
      summary: 'Vendor for clocks and event table hardware.',
      notes: [
        'High-value order potential',
        'Pairs with tournament-hosting programs',
        'Needs stronger lead tracking and quote workflow',
      ],
    ),
    OperatorVendor(
      id: 'bracketvision-displays',
      name: 'BracketVision Displays',
      lane: 'Scoring TV displays',
      status: 'Draft',
      marginNote: '15% target margin',
      summary: 'Display vendor for scoring TVs and event-room installs.',
      notes: [
        'Best positioned as an operator upgrade product',
        'Needs install and shipping language',
        'Strong bundle with clocks and laptop kits',
      ],
    ),
    OperatorVendor(
      id: 'wrestlefootwear-co',
      name: 'WrestleFootwear Co.',
      lane: 'Shoes',
      status: 'Live',
      marginNote: '10-16% margin range',
      summary: 'Dropship shoe supplier for athlete and parent-facing sales.',
      notes: [
        'Seasonal spike opportunity',
        'Good add-on from athlete onboarding',
        'Should support size and stock sync later',
      ],
    ),
  ];
}
