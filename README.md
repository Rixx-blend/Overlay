# Glass Bubble Overlay

WPF overlay for Windows 10/11.

## Build locally
Requires .NET 8 SDK:
```powershell
dotnet run
```

## Build without installing the SDK locally
GitHub Actions runs the Windows build automatically on every push to main.
Open the repository's Actions tab and download the `GlassBubbleOverlay-Windows` artifact.

## Controls
- Drag with the left mouse button.
- Right-click and choose Quitter.
- Press Escape to close.

## Optical settings
IOR 1.80, 90% thickness, 100% chromatic dispersion and 100% rim light are approximated with
2D WPF highlights and colored edge fringes. This is not a physically accurate 3D refraction
simulation. The Acrylic backdrop is provided by Windows and can vary with system settings.
