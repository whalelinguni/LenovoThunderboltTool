
# Thinkpad Thunderbolt Firmware Tool

## 'Thunderfault' name credit SMDFlea at badcaps.net

This readme was generated and I did not proof-read it or even read it to be honest. So it's either correct or somewhate correct or incorrect. For sure one of those. 

![Thinkpad Thunderbolt Firmware Tool](https://github.com/whalelinguni/LenovoThunderboltTool/blob/main/ThunderScreenShot.png)

## Overview

This script is designed to help manage Thinkpad Thunderbolt firmware operations. It includes features like extracting firmware installers, padding firmware files to a specific size, managing Lenovo drivers, and exporting device lists using DevManView.

**Note:** This script is 100% untested.

## Features

- **Lenovo Driver Manager**: Launches the Lenovo Driver Manager to download and manage drivers.
- **Extract Firmware Install**: Extracts firmware installers using `innounp`.
- **Pad TBT Firmware BIN**: Pads Thunderbolt firmware BIN files to 1 MB.
- **Device**: Launches DevManView for managing devices.
- **Export Device List**: Exports the list of devices using DevManView.
- **Quit**: Exits the script.

## Usage

1. Clone or download this repository.
2. Open PowerShell as an Administrator.
3. Navigate to the directory containing the script.
4. Run the script using the following command:

   \`\`\`powershell
   .\Thunderfault.ps1
   \`\`\`

5. Follow the on-screen instructions to select an operation.

## Menu

\`\`\`text
---  Thunderbolt Operations ---
-------------------------------
1. Lenovo Driver Manager
2. Extract Firmware Install
3. Pad TBT Firmware BIN
4. Device
5. Export device list
6. Quit
Select a task by number or Q to quit:
\`\`\`

## Notes

- Thank to SMDFlea at badcaps.net for the hilarious 'Thunderfault' naming. 

## Requirements

- PowerShell
- Required files like `Lenovo.Driver.Manager.exe`, `innounp.exe`, and `DevManView.exe` should be placed in the `bin` directory.

## Disclaimer

This script is provided "as is" without any warranties. Use it at your own risk. The author is not responsible for any damage caused by using this script.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
