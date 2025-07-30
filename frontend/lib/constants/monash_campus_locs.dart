enum MonashCampus { clayton, caulfield, peninsula, lawChambers }

enum MonashCampusCodes { cl, ca, pe, lc }

Map<MonashCampusCodes, MonashCampus> monashCodeToCampus = {
  MonashCampusCodes.cl: MonashCampus.clayton,
  MonashCampusCodes.ca: MonashCampus.caulfield,
  MonashCampusCodes.pe: MonashCampus.peninsula,
  MonashCampusCodes.lc: MonashCampus.lawChambers,
};

Map<MonashCampus, MonashCampusCodes> monashCampusToCode = {
  MonashCampus.clayton: MonashCampusCodes.cl,
  MonashCampus.caulfield: MonashCampusCodes.ca,
  MonashCampus.peninsula: MonashCampusCodes.pe,
  MonashCampus.lawChambers: MonashCampusCodes.lc,
};
