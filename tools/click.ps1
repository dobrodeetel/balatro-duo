# Left-click at screen coordinates (for UI checks of the test copy).
param([int]$X, [int]$Y)
Add-Type @"
using System; using System.Runtime.InteropServices;
public static class DuoMouse {
  [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
  [DllImport("user32.dll")] public static extern void mouse_event(uint f, uint dx, uint dy, uint d, IntPtr e);
}
"@
[DuoMouse]::SetCursorPos($X, $Y) | Out-Null
Start-Sleep -Milliseconds 300
[DuoMouse]::mouse_event(2, 0, 0, 0, [IntPtr]::Zero)
Start-Sleep -Milliseconds 80
[DuoMouse]::mouse_event(4, 0, 0, 0, [IntPtr]::Zero)
