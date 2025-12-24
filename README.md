# Hold For Me using ADB
A script that monitors your phone call and alerts you when someone picks up, so you don't have to listen to hold music.
Uses Android's Live Caption feature + OpenAI to detect when a human answers.

## Requirements

- [Live Caption](https://support.google.com/accessibility/android/answer/9350862) enabled on your phone
- USB debugging on your phone
- ADB (Android Debug Bridge) on your computer
- OpenAI API key
- `xmllint`, `jq`, `spd-say` (speech dispatcher)

## Setup

1. Copy the sample config and add your OpenAI API key:

   ```bash
   cp config.sample.sh config.sh
   # Edit config.sh with your OPENAI_API_KEY
   ```

2. Connect your phone via ADB:

   ```bash
   adb devices  # Verify connection
   ```

3. Enable Live Caption on your Android phone

## Usage

```bash
./run_live.sh
```

The script will:
1. Poll the phone's UI via ADB to read Live Caption text
2. Send captions to OpenAI to classify as "HOLD" or "PICKED"
3. Alert you with audio ("check call") when someone picks up
4. Press `c` to continue monitoring after an alert, or `Ctrl+C` to stop

# Example output (no answer)

    $ ./run_live.sh 
    [20:48:14] Saved: dump1/20251224_204814_1.xml (md5: 4b3a9d95369e3bc9a0b82295be4b2a76)
    XXX
    All of our representatives are currently busy.
    (Music)
    (Music)
    Representatives are currently busy.
    (Music)
    All of our representatives are currently busy.
    (Music)
    XXX
    HOLD
    [20:48:23] No change (md5: 4b3a9d95369e3bc9a0b82295be4b2a76)    
    [20:48:28] Saved: dump1/20251224_204828_2.xml (md5: ef17731a6e401ffd88c767cf18649f8c)
    XXX
    (Music)
    Representatives are currently busy.
    (Music)
    All of our representatives are currently busy.
    (Music)
    All that representatives are currently busy.
    XXX
    HOLD
    ^C

# Example output (simulated answer)

    $ ./run_live.sh 
    [20:49:46] Saved: dump1/20251224_204946_1.xml (md5: f4374a50e8aee4c26d01f8a5353b8461)
    XXX
    All that representatives are currently busy.
    (Music)
    Of a representatives are currently busy.
    (Music)
    All the representatives are currently busy.
    (Music)
    XXX
    HOLD
    !!! CHECK CALL !!!
    Press 'c' to continue monitoring, Ctrl+C to stop the script
    cContinuing...
    [20:49:58] No change (md5: f4374a50e8aee4c26d01f8a5353b8461)    ^C

# Example Call With Live Captions
![Example Call With Live Captions](./.assets/Screenshot_20251224_205054_Call_redacted.jpg)