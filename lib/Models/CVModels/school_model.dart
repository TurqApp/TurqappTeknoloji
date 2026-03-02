class CvSchoolModel {
  String school;
  String branch;
  String lastYear;

  CvSchoolModel({
    required this.school,
    required this.branch,
    required this.lastYear,
  });

  Map<String, dynamic> toMap() => {
    "school": school,
    "branch": branch,
    "lastYear": lastYear,
  };

  factory CvSchoolModel.fromMap(Map<String, dynamic> map) => CvSchoolModel(
    school: map["school"] ?? "",
    branch: map["branch"] ?? "",
    lastYear: map["lastYear"] ?? "",
  );
}

class CVLanguegeModel {
  String languege;
  num level;
  num index;

  CVLanguegeModel({
    required this.languege,
    required this.level,
    required this.index,
  });

  Map<String, dynamic> toMap() => {
    "languege": languege,
    "level": level,
    "index": index,
  };

  factory CVLanguegeModel.fromMap(Map<String, dynamic> map) => CVLanguegeModel(
    languege: map["languege"] ?? "",
    level: map["level"] ?? 0,
    index: map["index"] ?? 0,
  );
}

class CVExperinceModel {
  String company;
  String position;
  String year1;
  String year2;
  String description;

  CVExperinceModel({
    required this.company,
    required this.position,
    required this.year1,
    required this.year2,
    this.description = '',
  });

  Map<String, dynamic> toMap() => {
    "company": company,
    "position": position,
    "year1": year1,
    "year2": year2,
    "description": description,
  };

  factory CVExperinceModel.fromMap(Map<String, dynamic> map) => CVExperinceModel(
    company: map["company"] ?? "",
    position: map["position"] ?? "",
    year1: map["year1"] ?? "",
    year2: map["year2"] ?? "",
    description: map["description"] ?? "",
  );
}

class CVReferenceHumans {
  String nameSurname;
  String phone;

  CVReferenceHumans({
    required this.nameSurname,
    required this.phone,
  });

  Map<String, dynamic> toMap() => {
    "nameSurname": nameSurname,
    "phone": phone,
  };

  factory CVReferenceHumans.fromMap(Map<String, dynamic> map) => CVReferenceHumans(
    nameSurname: map["nameSurname"] ?? "",
    phone: map["phone"] ?? "",
  );
}

class CvModel {
  final String firstName;
  final String lastName;
  final String mail;
  final String phone;
  final String linkedin;
  final String about;
  final bool findingJob;
  final List<CvSchoolModel> schools;
  final List<CVLanguegeModel> languages;
  final List<CVExperinceModel> experiences;
  final List<CVReferenceHumans> references;
  final List<String> skills;

  CvModel({
    required this.firstName,
    required this.lastName,
    required this.mail,
    required this.phone,
    required this.linkedin,
    required this.about,
    required this.schools,
    required this.languages,
    required this.experiences,
    required this.references,
    required this.findingJob,
    this.skills = const [],
  });

  Map<String, dynamic> toMap() => {
    "firstName": firstName,
    "lastName": lastName,
    "mail": mail,
    "phone": phone,
    "linkedin": linkedin,
    "about": about,
    "okullar": schools.map((e) => e.toMap()).toList(),
    "diller": languages.map((e) => e.toMap()).toList(),
    "deneyim": experiences.map((e) => e.toMap()).toList(),
    "referans": references.map((e) => e.toMap()).toList(),
    "findingJob": findingJob,
    "skills": skills,
  };

  factory CvModel.fromMap(Map<String, dynamic> map) => CvModel(
    firstName: map["firstName"] ?? "",
    lastName: map["lastName"] ?? "",
    findingJob: map["findingJob"] ?? false,
    mail: map["mail"] ?? "",
    phone: map["phone"] ?? "",
    linkedin: map["linkedin"] ?? "",
    about: map["about"] ?? "",
    schools: (map["okullar"] as List<dynamic>? ?? [])
        .map((e) => CvSchoolModel.fromMap(e))
        .toList(),
    languages: (map["diller"] as List<dynamic>? ?? [])
        .map((e) => CVLanguegeModel.fromMap(e))
        .toList(),
    experiences: (map["deneyim"] as List<dynamic>? ?? [])
        .map((e) => CVExperinceModel.fromMap(e))
        .toList(),
    references: (map["referans"] as List<dynamic>? ?? [])
        .map((e) => CVReferenceHumans.fromMap(e))
        .toList(),
    skills: (map["skills"] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList(),
  );
}
