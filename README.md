# GymTrack

App mobile (Flutter) per registrare gli allenamenti in palestra e tenere traccia dei progressi.
Tutto in locale sul telefono, nessun account e nessun costo.

## Funzioni

- **Schede di allenamento** personalizzabili: nome, esercizi (dalla libreria integrata per gruppo muscolare o personalizzati), serie, ripetizioni e peso
- **Allenamento attivo**: compilazione rapida di rip./kg per ogni serie con spunta, cronometro di sessione e salvataggio automatico al termine
- **Storico**: tutti gli allenamenti raggruppati per periodo, con dettaglio delle serie
- **Progressi**: volume settimanale (istogramma, ultime 8 settimane), carico massimo per esercizio nel tempo (grafico a linea), statistiche riassuntive
- **Sfide con gli amici**: crei una sfida (volume totale, allenamenti completati o carico massimo su un esercizio), inviti l'amico con un codice da condividere via WhatsApp/SMS, e vi confrontate scambiandovi i codici risultato. Funziona completamente offline, senza account e senza server
- **Libreria esercizi** di ~35 esercizi per petto, dorso, gambe, spalle, bicipiti, tricipiti e core

I dati sono salvati in un database SQLite sul dispositivo.

## Scaricare l'app compilata

A ogni push su `main` la GitHub Action `.github/workflows/build-apk.yml` compila l'app e pubblica `GymTrack.apk` (Android) e `GymTrack.ipa` (iOS, non firmato) nelle [release del repository](https://github.com/antonot7326-wq/gym-tracker/releases).

**Web (il più semplice, funziona su iPhone/iOS/Android/Desktop)**: l'app è pubblica su [antonot7326-wq.github.io/gym-tracker](https://antonot7326-wq.github.io/gym-tracker/) — apri il link, usando in Chrome (Android) o Safari (iPhone) puoi "Aggiungere alla schermata Home" e si usa come app. I dati restano nel browser del dispositivo.

**Android**: scarica `GymTrack.apk` dalla release più recente, mandalo al telefono e installalo (consenti origini sconosciute).

**iOS**: l'IPA non firmata non si installa con un tap. Serve un computer (Windows/Mac) con [AltServer + AltStore](https://altstore.io) o [Sideloadly](https://sideloadly.io): installano l'app usando il tuo Apple ID gratuito (limite Apple: 7 giorni prima di reinstallare, max 3 app). Per l'installazione permanente serve un account Apple Developer (99 $/anno).

## Compilare in locale

Requisiti: [Flutter SDK](https://docs.flutter.dev/get-started/install) stabile.

```bash
flutter pub get
flutter devices   # controlla che il telefono/emulatore sia visibile
flutter run       # avvio rapido in debug
```

Per installare l'APK su Android:

```bash
flutter build apk --release
# APK in build/app/outputs/flutter-apk/app-release.apk
```

Per iOS serve un Mac con Xcode:

```bash
flutter build ios --release
```

## Struttura

```
lib/
  main.dart                   # app, tema
  db.dart                     # SQLite (schede, sessioni, serie)
  models.dart                 # modelli di dati
  exercise_library.dart       # libreria esercizi per gruppo muscolare
  home_screen.dart            # navigazione a 3 schede
  template_edit_screen.dart   # crea/modifica schede
  active_workout_screen.dart  # allenamento in corso
  history_screen.dart         # storico e dettaglio sessione
  stats_screen.dart           # grafici e statistiche
  challenges_screen.dart      # sfide con gli amici e classifiche
  challenge_codec.dart        # codici invito/risultato da condividere
```
