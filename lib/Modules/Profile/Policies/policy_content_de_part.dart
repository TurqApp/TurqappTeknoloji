part of 'policy_content.dart';

const List<PolicyDocument> _germanPolicies = [
  PolicyDocument(
    id: 'agreement',
    title: 'Mitgliedschaft und Vereinbarung',
    summary:
        'Definiert die Nutzung von TurqApp, die Rolle der Plattform, Nutzerpflichten, Urheberrechte und den Sanktionsrahmen.',
    updatedAt: '19. März 2026',
    icon: CupertinoIcons.doc_plaintext,
    sections: [
      PolicySection(
        title: 'Umfang der Vereinbarung',
        body: [
          'Diese Vereinbarung gilt für soziale Inhalte, Nachrichten, Bildung, Stipendien, Nachhilfe, Stellenanzeigen, Bewerbungsprozesse, marktplatzähnliche Bereiche und alle damit verbundenen digitalen Oberflächen innerhalb von TurqApp.',
          'Das Erstellen eines Kontos, die Anmeldung oder die Nutzung von Funktionen in TurqApp bedeutet, dass dieser Text akzeptiert wird.',
        ],
      ),
      PolicySection(
        title: 'Rolle der Plattform',
        body: [
          'TurqApp ist nicht unmittelbare Vertragspartei für Kommunikation, Bewerbungen, Arbeitsverhältnisse, Nachhilfeverhältnisse, Stipendienprozesse, Produktübertragungen, Zahlungen oder Lieferungen zwischen Nutzern.',
          'Die Plattform stellt technische Infrastruktur und Community-Sicherheit bereit, garantiert jedoch nicht die Richtigkeit jedes nutzergenerierten Inhalts, jeder Anzeige oder jedes Versprechens.',
        ],
      ),
      PolicySection(
        title: 'Verpflichtungen der Nutzer',
        bullets: [
          'Genaue, aktuelle und nicht irreführende Informationen bereitstellen',
          'Andere nicht imitieren',
          'Rechtswidrige, betrügerische oder ausbeuterische Nutzung vermeiden',
          'Die Plattform nicht so nutzen, dass die Community gestört, Systeme manipuliert oder Sicherheit geschwächt wird',
          'Für Aktivitäten verantwortlich bleiben, die über das eigene Konto erfolgen',
        ],
      ),
      PolicySection(
        title: 'Verantwortung für Inhalte',
        body: [
          'Für Texte, Bilder, Videos, Dokumente, Kommentare, Profilfelder, Anzeigen und ähnliche Inhalte in TurqApp ist in erster Linie der hochladende Nutzer verantwortlich.',
          'TurqApp kann solche Inhalte bei Bedarf prüfen, indexieren, technisch verarbeiten, in ihrer Sichtbarkeit einschränken oder entfernen.',
        ],
      ),
      PolicySection(
        title: 'Urheberrecht und geistiges Eigentum',
        body: [
          'Nutzer erklären, dass sie über die erforderlichen Rechte an hochgeladenen Inhalten verfügen oder ausreichende Berechtigungen zur Freigabe besitzen.',
          'Inhalte, die gegen geltendes Recht zum geistigen Eigentum verstoßen, dürfen nicht auf TurqApp gehostet werden.',
          'Die Marke TurqApp, die Oberfläche, Designelemente, Softwareinfrastruktur, Datenorganisation, das Logo, Serviceabläufe und originale Anwendungselemente gehören TurqApp oder den jeweiligen Rechteinhabern.',
        ],
        bullets: [
          'Unerlaubtes Kopieren, Vervielfältigen, erneutes Veröffentlichen oder kommerzielle Nutzung ist untersagt',
          'Inhalte mit Urheberrechtsverletzungen können vorübergehend oder dauerhaft entfernt werden',
          'Wiederholte Verstöße können zu Kontobeschränkungen oder Schließung führen',
        ],
      ),
      PolicySection(
        title: 'TurqApp erteilte Lizenz',
        body: [
          'Der Nutzer erlaubt, dass auf TurqApp geteilte Inhalte soweit gespeichert, verarbeitet, angezeigt, an verschiedene Gerätegrößen angepasst, in Vorschauen oder Kurzlink-Systemen genutzt und zu Moderationszwecken überprüft werden, wie es für die Bereitstellung des Dienstes erforderlich ist.',
          'Diese Erlaubnis überträgt das Eigentum am Inhalt nicht auf TurqApp; sie umfasst nur technische Nutzungen, die für Betrieb und Sicherheit erforderlich sind.',
        ],
      ),
      PolicySection(
        title: 'Durchsetzung und Rechtevorbehalt',
        bullets: [
          'TurqApp kann Inhalte entfernen oder ausblenden',
          'TurqApp kann Kontofunktionen einschränken',
          'TurqApp kann Nutzer vorübergehend oder dauerhaft von der Plattform ausschließen',
          'TurqApp kann bei Bedarf Behörden informieren',
        ],
      ),
      PolicySection(
        title: 'Haftungsbeschränkung',
        body: [
          'Soweit gesetzlich zulässig, übernimmt TurqApp direkte oder indirekte Risiken aus Transaktionen zwischen Nutzern, Verhalten Dritter, Ergebnissen von Anzeigen, Job- oder Stipendienzusagen, Nachhilfebeziehungen oder Gesprächen außerhalb der Plattform nicht vollständig.',
          'Die Plattform garantiert nicht, dass alle Risiken beseitigt werden; sie will jedoch durch Sicherheits-, Melde- und Moderationstools angemessenen Schutz bieten.',
        ],
      ),
    ],
  ),
  PolicyDocument(
    id: 'privacy',
    title: 'Datenschutz',
    summary:
        'Erklärt, welche Arten von Informationen innerhalb von TurqApp entstehen können und wie sie verwendet werden können.',
    updatedAt: '19. März 2026',
    icon: CupertinoIcons.lock_shield,
    sections: [
      PolicySection(
        title: 'Überblick',
        body: [
          'TurqApp betrachtet Datenschutz nicht nur als technisches Thema, sondern als zentralen Bestandteil des App-Erlebnisses.',
          'Diese Richtlinie beschreibt die allgemeine Nutzung von Informationen, die in sozialen Inhalten, Nachrichten, Bildung, Stipendien, Nachhilfe, Stellenanzeigen und Marktplatzoberflächen entstehen können.',
        ],
      ),
      PolicySection(
        title: 'Welche Informationen erhoben werden können',
        bullets: [
          'Konto- und Profilinformationen',
          'Geteilte Beiträge, Storys, Kommentare, Nachrichten und andere Inhalte',
          'Informationen aus Stipendien-, Nachhilfe-, Stellen- und Marktplatzbereichen',
          'Bewerbungen, Bewertungen und Interaktionsdaten',
          'Geräte-, App-Version-, Fehler- und Sicherheitsdaten',
          'Standort-, Kamera-, Galerie-, Benachrichtigungs- oder Kontaktdaten bei erteilter Berechtigung',
        ],
      ),
      PolicySection(
        title: 'Warum wir Informationen verwenden',
        bullets: [
          'Um die App zu betreiben und das Kontoerlebnis zu verwalten',
          'Um Inhalte anzuzeigen, zu sortieren und zuzuordnen',
          'Um Nachrichten-, Bewerbungs- und Anzeigenabläufe auszuführen',
          'Um Sicherheitsrisiken, Spam und Missbrauch zu verringern',
          'Um Supportanfragen und Nutzerberichte zu prüfen',
          'Um die App zu verbessern und Probleme zu beheben',
        ],
      ),
      PolicySection(
        title: 'Datenschutz-Erwartungen',
        body: [
          'Einige Inhalte, die du auf TurqApp teilst, können aufgrund der Art der Oberfläche für andere Nutzer sichtbar sein.',
          'Gemeldete Inhalte, sicherheitsrelevante Vorfälle oder Situationen mit rechtlichen Verpflichtungen können eingeschränkt überprüft werden.',
        ],
      ),
      PolicySection(
        title: 'Deine Wahlmöglichkeiten',
        bullets: [
          'Profilinformationen aktualisieren',
          'Bestimmte Berechtigungen in den Geräteeinstellungen verwalten',
          'Benachrichtigungseinstellungen ändern',
          'Anfragen zu Kontolöschung oder Daten stellen',
        ],
      ),
    ],
  ),
  PolicyDocument(
    id: 'notice',
    title: 'Datenschutzhinweis',
    summary:
        'Beschreibt auf allgemeiner Ebene, welche Datenkategorien bei der Nutzung von TurqApp verarbeitet werden können und zu welchen Zwecken.',
    updatedAt: '19. März 2026',
    icon: CupertinoIcons.doc_text_search,
    sections: [
      PolicySection(
        title: 'Umfang',
        body: [
          'TurqApp umfasst digitale Oberflächen wie soziales Teilen, Bildungsinhalte, Stipendienanzeigen, Nachhilfeanzeigen, Stellenanzeigen, Bewerbungsabläufe und Nachrichten.',
          'Bei der Nutzung dieser Dienste können bestimmte personenbezogene Daten verarbeitet werden.',
        ],
      ),
      PolicySection(
        title: 'Kategorien verarbeitbarer Daten',
        bullets: [
          'Konto- und Profilinformationen',
          'Kontaktdaten',
          'Hochgeladene Texte, Bilder, Videos und Dokumente',
          'Kommentare, Nachrichten, Speicherungen, Likes und Meldedaten',
          'Anzeigen-, Bewerbungs- und Bewertungsinformationen',
          'Stadt-, Bezirks- und – sofern erlaubt – Standortdaten',
          'Geräte-, Sitzungs-, Fehler- und Sicherheitsprotokolle',
        ],
      ),
      PolicySection(
        title: 'Zwecke der Verarbeitung',
        bullets: [
          'Konten erstellen und verwalten',
          'Inhalte, Anzeigen, Bewerbungen und Nachrichtenabläufe betreiben',
          'Sicherheit, Spam-Prävention und Missbrauchserkennung durchführen',
          'Melde- und Moderationsprozesse ausführen',
          'Technische Probleme beheben und Leistung verbessern',
          'Rechtliche Verpflichtungen erfüllen',
        ],
      ),
      PolicySection(
        title: 'Speicherung und Löschung',
        body: [
          'Daten können gespeichert werden, solange der Zweck des Dienstes besteht oder geltende rechtliche Anforderungen fortbestehen.',
          'Wenn sie nicht mehr benötigt werden, werden Lösch-, Vernichtungs- oder Anonymisierungsprozesse innerhalb angemessener Frist angewandt.',
        ],
      ),
    ],
  ),
  PolicyDocument(
    id: 'community',
    title: 'Community',
    summary:
        'Erklärt die Verhaltensstandards innerhalb von TurqApp und die Arten von Inhalten, die nicht akzeptiert werden.',
    updatedAt: '19. März 2026',
    icon: CupertinoIcons.person_2_fill,
    sections: [
      PolicySection(
        title: 'Bleib respektvoll',
        bullets: [
          'Beleidige niemanden',
          'Droh niemandem',
          'Demütige keine Personen',
          'Stelle niemanden an den Pranger oder initiiere gezielte Angriffe',
        ],
      ),
      PolicySection(
        title: 'Sei ehrlich und realistisch',
        bullets: [
          'Nutze keine Fake-Konten',
          'Imitiere keine anderen Personen',
          'Teile keine irreführenden Anzeigen, Fake-Profile oder falschen Referenzen',
        ],
      ),
      PolicySection(
        title: 'Gefährde keine Sicherheit',
        bullets: [
          'Begehe keinen Betrug',
          'Dränge niemanden zu riskanten Zahlungen außerhalb der Plattform',
          'Versuche nicht, sensible Informationen von Nutzern zu sammeln',
          'Veröffentliche keine privaten Informationen ohne Zustimmung',
        ],
      ),
      PolicySection(
        title: 'Kinderschutz',
        body: [
          'Jedes Verhalten gegenüber Minderjährigen, das unangemessene Kommunikation, Manipulation, sexuelle Inhalte, Druck zu Treffen oder Ausbeutung beinhaltet, ist strikt verboten.',
        ],
      ),
    ],
  ),
  PolicyDocument(
    id: 'moderation',
    title: 'Sicherheit und Moderation',
    summary:
        'Erklärt, wie TurqApp auf Meldungen, Sicherheitssignale und Verstöße reagieren kann.',
    updatedAt: '19. März 2026',
    icon: CupertinoIcons.shield_lefthalf_fill,
    sections: [
      PolicySection(
        title: 'Was wir prüfen können',
        bullets: [
          'Beiträge und Storys',
          'Kommentare',
          'Profilfelder',
          'Stipendien-, Nachhilfe-, Stellen- und Marktplatzinhalte',
          'Nachrichten und Bewerbungsanhänge',
          'Bilder, Videos und Dokumente',
        ],
      ),
      PolicySection(
        title: 'Quellen der Moderation',
        bullets: [
          'Nutzermeldungen',
          'Automatisierte Sicherheitsprüfungen',
          'Spam- oder Missbrauchssignale',
          'Erkennung unangemessener Bilder oder Medien',
          'Wiederholte Verstoßhistorie',
        ],
      ),
      PolicySection(
        title: 'Bereiche schneller Intervention',
        bullets: [
          'Risiken für die Sicherheit von Kindern',
          'Sexueller Missbrauch oder Ausbeutung',
          'Gewaltdrohungen',
          'Betrug und Fake-Anzeigen',
          'Offenlegung privater Informationen',
          'Schwere Belästigung und koordinierte Angriffe',
        ],
      ),
      PolicySection(
        title: 'Mögliche Maßnahmen',
        bullets: [
          'Verwarnung aussprechen',
          'Inhalte entfernen',
          'Inhalte vorübergehend ausblenden',
          'Kontofunktionen einschränken',
          'Vorübergehende Sperre',
          'Dauerhafte Kontoschließung',
        ],
      ),
    ],
  ),
];
