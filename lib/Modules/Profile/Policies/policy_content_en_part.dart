part of 'policy_content.dart';

const List<PolicyDocument> _englishPolicies = [
  PolicyDocument(
    id: 'agreement',
    title: 'Membership and Agreement',
    summary:
        'Defines TurqApp usage, the platform’s role, user responsibilities, copyright, and enforcement framework.',
    updatedAt: '19 March 2026',
    icon: CupertinoIcons.doc_plaintext,
    sections: [
      PolicySection(
        title: 'Scope of the Agreement',
        body: [
          'This agreement applies to social content, messaging, education, scholarships, tutoring, job listings, application processes, marketplace-like areas, and all connected digital surfaces within TurqApp.',
          'Creating an account, signing in, or using features within TurqApp means this text is accepted.',
        ],
      ),
      PolicySection(
        title: 'Role of the Platform',
        body: [
          'TurqApp is not the direct party to communications, applications, employment relationships, tutoring relationships, scholarship processes, product transfers, payments, or deliveries between users.',
          'The platform provides technology infrastructure and community safety, but does not guarantee the accuracy of every piece of user-generated content, listing, or promise.',
        ],
      ),
      PolicySection(
        title: 'User Commitments',
        bullets: [
          'Provide accurate, up-to-date, and non-misleading information',
          'Do not impersonate others',
          'Avoid unlawful, fraudulent, or exploitative use',
          'Do not use the platform in ways that disrupt the community, manipulate systems, or weaken safety',
          'Remain responsible for actions carried out through your account',
        ],
      ),
      PolicySection(
        title: 'Content Responsibility',
        body: [
          'The user who uploads text, images, videos, documents, comments, profile fields, listings, and similar content in TurqApp is primarily responsible for that content.',
          'TurqApp may review, index, technically process, limit the visibility of, or remove such content when necessary.',
        ],
      ),
      PolicySection(
        title: 'Copyright and Intellectual Property',
        body: [
          'Users agree that they hold the necessary rights to the content they upload or that they have sufficient permission to share it.',
          'Content that violates applicable intellectual property laws, including copyright legislation, must not be hosted on TurqApp.',
          'The TurqApp brand, interface, design elements, software infrastructure, data organization, logo, service flows, and original application elements belong to TurqApp or the relevant rights holders.',
        ],
        bullets: [
          'Unauthorized copying, reproduction, republication, or commercial use is prohibited',
          'Content subject to copyright notices may be removed temporarily or permanently',
          'Repeated violations may lead to account restrictions or closure',
        ],
      ),
      PolicySection(
        title: 'License Granted to TurqApp',
        body: [
          'The user allows content shared on TurqApp to be stored, processed, displayed, adapted to different device sizes, used in previews or short-link systems, and reviewed for moderation purposes to the extent necessary to provide the service.',
          'This permission does not transfer ownership of the content to TurqApp; it only covers technical uses needed for service operation and safety.',
        ],
      ),
      PolicySection(
        title: 'Enforcement and Reservation of Rights',
        bullets: [
          'TurqApp may remove or hide content',
          'TurqApp may restrict account features',
          'TurqApp may temporarily or permanently remove a user from the platform',
          'TurqApp may notify official authorities when required',
        ],
      ),
      PolicySection(
        title: 'Limitation of Liability',
        body: [
          'To the fullest extent permitted by law, TurqApp does not fully assume direct or indirect risks arising from transactions between users, third-party behavior, listing outcomes, job or scholarship acceptances, tutoring relationships, or off-platform discussions.',
          'The platform does not guarantee that all risks will be eliminated; however, it aims to provide reasonable protection through safety, reporting, and moderation tools.',
        ],
      ),
    ],
  ),
  PolicyDocument(
    id: 'privacy',
    title: 'Privacy',
    summary:
        'Explains what kinds of information may arise within TurqApp and how they may be used.',
    updatedAt: '19 March 2026',
    icon: CupertinoIcons.lock_shield,
    sections: [
      PolicySection(
        title: 'Overview',
        body: [
          'TurqApp sees privacy not only as a technical issue, but as a core part of the app experience.',
          'This policy outlines the general use of information that may arise across social content, messaging, education, scholarships, tutoring, job listings, and marketplace surfaces.',
        ],
      ),
      PolicySection(
        title: 'Information That May Be Collected',
        bullets: [
          'Account and profile information',
          'Shared posts, stories, comments, messages, and other content',
          'Information entered into scholarship, tutoring, job listing, and marketplace areas',
          'Applications, reviews, and user interaction records',
          'Device, app version, error, and security records',
          'Location, camera, gallery, notifications, or contacts data when permission is granted',
        ],
      ),
      PolicySection(
        title: 'Why We Use Information',
        bullets: [
          'To operate the app and manage the account experience',
          'To display, rank, and match content',
          'To run messaging, application, and listing flows',
          'To reduce safety risks, spam, and abuse',
          'To review support requests and user reports',
          'To improve the app and fix problems',
        ],
      ),
      PolicySection(
        title: 'Privacy Expectations',
        body: [
          'Some content you share on TurqApp may be visible to other users by the nature of the surface where it is posted.',
          'Reported content, safety-risk incidents, or situations involving legal obligations may be subject to limited review.',
        ],
      ),
      PolicySection(
        title: 'Your Choices',
        bullets: [
          'Update profile information',
          'Manage certain permissions from device settings',
          'Change notification preferences',
          'Submit account closure or data-related requests',
        ],
      ),
    ],
  ),
  PolicyDocument(
    id: 'notice',
    title: 'Privacy Notice',
    summary:
        'Outlines, at a general level, which categories of data may be processed while using TurqApp and for what purposes.',
    updatedAt: '19 March 2026',
    icon: CupertinoIcons.doc_text_search,
    sections: [
      PolicySection(
        title: 'Scope',
        body: [
          'TurqApp covers digital surfaces such as social sharing, educational content, scholarship listings, tutoring listings, job listings, application flows, and messaging.',
          'Certain personal data may be processed while these services are used.',
        ],
      ),
      PolicySection(
        title: 'Categories of Data That May Be Processed',
        bullets: [
          'Account and profile information',
          'Contact information',
          'Uploaded text, images, videos, and documents',
          'Comments, messages, saves, likes, and report records',
          'Listing, application, and review information',
          'City, district, and, when allowed, location data',
          'Device, session, error, and security logs',
        ],
      ),
      PolicySection(
        title: 'Purposes of Processing',
        bullets: [
          'To create and manage accounts',
          'To operate content, listings, applications, and messaging flows',
          'To perform security, spam prevention, and abuse detection',
          'To run reporting and moderation processes',
          'To resolve technical issues and improve performance',
          'To comply with legal obligations',
        ],
      ),
      PolicySection(
        title: 'Retention and Deletion',
        body: [
          'Data may be retained as long as the service purpose continues or applicable legal requirements remain in effect.',
          'When no longer needed, deletion, destruction, or anonymization processes are applied within a reasonable time.',
        ],
      ),
    ],
  ),
  PolicyDocument(
    id: 'community',
    title: 'Community',
    summary:
        'Explains behavior standards within TurqApp and the types of content that will not be accepted.',
    updatedAt: '19 March 2026',
    icon: CupertinoIcons.person_2_fill,
    sections: [
      PolicySection(
        title: 'Be Respectful',
        bullets: [
          'Do not insult others',
          'Do not threaten others',
          'Do not humiliate people',
          'Do not target individuals or encourage dogpiling',
        ],
      ),
      PolicySection(
        title: 'Be Honest and Realistic',
        bullets: [
          'Do not use fake accounts',
          'Do not impersonate others',
          'Do not share misleading listings, fake profiles, or false references',
        ],
      ),
      PolicySection(
        title: 'Do Not Endanger Safety',
        bullets: [
          'Do not commit fraud',
          'Do not force risky off-platform payments',
          'Do not attempt to collect sensitive information from users',
          'Do not expose private information without consent',
        ],
      ),
      PolicySection(
        title: 'Child Safety',
        body: [
          'Any behavior targeting minors involving inappropriate communication, manipulation, sexual content, pressure to meet, or exploitation is strictly prohibited.',
        ],
      ),
    ],
  ),
  PolicyDocument(
    id: 'moderation',
    title: 'Safety and Moderation',
    summary:
        'Explains how TurqApp may respond to reports, security signals, and violations.',
    updatedAt: '19 March 2026',
    icon: CupertinoIcons.shield_lefthalf_fill,
    sections: [
      PolicySection(
        title: 'What We May Review',
        bullets: [
          'Posts and stories',
          'Comments',
          'Profile fields',
          'Scholarship, tutoring, job listing, and marketplace content',
          'Messaging and application attachments',
          'Images, videos, and documents',
        ],
      ),
      PolicySection(
        title: 'Moderation Sources',
        bullets: [
          'User reports',
          'Automated safety checks',
          'Spam or abuse signals',
          'Inappropriate visual or media detection',
          'Repeated violation history',
        ],
      ),
      PolicySection(
        title: 'Rapid Intervention Areas',
        bullets: [
          'Child safety risks',
          'Sexual abuse or exploitation',
          'Threats of violence',
          'Fraud and fake listings',
          'Disclosure of private information',
          'Severe harassment and coordinated targeting',
        ],
      ),
      PolicySection(
        title: 'Possible Actions',
        bullets: [
          'Issuing a warning',
          'Removing content',
          'Temporarily hiding content',
          'Restricting account features',
          'Temporary suspension',
          'Permanent account closure',
        ],
      ),
    ],
  ),
];
