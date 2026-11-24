class ExerciseLibrary {
  static const Map<String, List<String>> byGroup = {
    'Petto': [
      'Panca piana bilanciere',
      'Panca inclinata bilanciere',
      'Panca manubri',
      'Chest press',
      'Croci ai cavi',
      'Push-up',
    ],
    'Dorso': [
      'Trazioni alla sbarra',
      'Lat machine',
      'Pulley basso',
      'Rematore bilanciere',
      'Rematore manubrio',
      'Stacco eracente',
    ],
    'Gambe': [
      'Squat bilanciere',
      'Pressa 45',
      'Leg extension',
      'Leg curl',
      'Affondi manubri',
      'Stacco rumeno',
      'Calf in piedi',
    ],
    'Spalle': [
      'Lento avanti bilanciere',
      'Lento avanti manubri',
      'Alzate laterali',
      'Alzate frontali',
      'Military press',
      'Face pull',
    ],
    'Bicipiti': [
      'Curl bilanciere',
      'Curl manubri alternato',
      'Curl panca Scott',
      'Curl ai cavi',
      'Martello',
    ],
    'Tricipiti': [
      'French press',
      'Push-down ai cavi',
      'Dip alle parallele',
      'Push-up presa stretta',
      'Estensioni sopra la testa',
    ],
    'Addome e core': [
      'Crunch a terra',
      'Crunch ai cavi',
      'Plank',
      'Russian twist',
      'Hanging leg raise',
    ],
  };

  static List<String> get all =>
      byGroup.values.expand((l) => l).toList(growable: false);
}
