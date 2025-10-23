using System;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Windows.Forms;

class PauseRemapper
{
    private const int WH_KEYBOARD_LL = 13;
    private const int WM_KEYDOWN = 0x0100;
    private const int WM_KEYUP = 0x0101;
    private const int WM_SYSKEYDOWN = 0x0104;
    private const int WM_SYSKEYUP = 0x0105;

    private static LowLevelKeyboardProc _proc = HookCallback;
    private static IntPtr _hookID = IntPtr.Zero;
    private static bool pauseIsPressed = false;
    private static bool tabPressedWithPause = false;
    private static bool altIsHeld = false;

    [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    private static extern IntPtr SetWindowsHookEx(int idHook, LowLevelKeyboardProc lpfn, IntPtr hMod, uint dwThreadId);

    [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool UnhookWindowsHookEx(IntPtr hhk);

    [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    private static extern IntPtr CallNextHookEx(IntPtr hhk, int nCode, IntPtr wParam, IntPtr lParam);

    [DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    private static extern IntPtr GetModuleHandle(string lpModuleName);

    [DllImport("user32.dll")]
    private static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, UIntPtr dwExtraInfo);

    private const int KEYEVENTF_KEYUP = 0x0002;
    private const byte VK_CONTROL = 0x11;
    private const byte VK_MENU = 0x12; // Alt key
    private const byte VK_TAB = 0x09;
    private const byte VK_PAUSE = 0x13;
    private const byte VK_F4 = 0x73;
    private const byte VK_LWIN = 0x5B; // Left Windows key
    private const byte VK_S = 0x53;

    private delegate IntPtr LowLevelKeyboardProc(int nCode, IntPtr wParam, IntPtr lParam);

    static void Main()
    {
        _hookID = SetHook(_proc);
        Console.WriteLine("Pause key remapper running...");
        Console.WriteLine("Pause = Ctrl");
        Console.WriteLine("Pause + Tab = Alt + Tab");
        Console.WriteLine("F4 = Windows Key");
        Console.WriteLine("Press Ctrl+C to exit");
        Application.Run();
        UnhookWindowsHookEx(_hookID);
    }

    private static IntPtr SetHook(LowLevelKeyboardProc proc)
    {
        using (Process curProcess = Process.GetCurrentProcess())
        using (ProcessModule curModule = curProcess.MainModule)
        {
            return SetWindowsHookEx(WH_KEYBOARD_LL, proc, GetModuleHandle(curModule.ModuleName), 0);
        }
    }

    private static IntPtr HookCallback(int nCode, IntPtr wParam, IntPtr lParam)
    {
        if (nCode >= 0)
        {
            int vkCode = Marshal.ReadInt32(lParam);
            bool isKeyDown = (wParam == (IntPtr)WM_KEYDOWN || wParam == (IntPtr)WM_SYSKEYDOWN);
            bool isKeyUp = (wParam == (IntPtr)WM_KEYUP || wParam == (IntPtr)WM_SYSKEYUP);

            // Handle Pause key
            if (vkCode == VK_PAUSE)
            {
                if (isKeyDown && !pauseIsPressed)
                {
                    pauseIsPressed = true;
                    keybd_event(VK_CONTROL, 0, 0, UIntPtr.Zero); // Ctrl down
                    return (IntPtr)1; // Block original Pause
                }
                else if (isKeyUp)
                {
                    pauseIsPressed = false;
                    if (!tabPressedWithPause)
                    {
                        keybd_event(VK_CONTROL, 0, KEYEVENTF_KEYUP, UIntPtr.Zero); // Ctrl up
                    }
                    else if (altIsHeld)
                    {
                        // Release Alt when Pause is released
                        keybd_event(VK_MENU, 0, KEYEVENTF_KEYUP, UIntPtr.Zero);
                        altIsHeld = false;
                    }
                    tabPressedWithPause = false;
                    return (IntPtr)1; // Block original Pause
                }
            }

            // Handle Tab key when Pause is pressed
            if (vkCode == VK_TAB && pauseIsPressed)
            {
                if (isKeyDown)
                {
                    tabPressedWithPause = true;
                    // Release Ctrl, press/hold Alt, tap Tab
                    keybd_event(VK_CONTROL, 0, KEYEVENTF_KEYUP, UIntPtr.Zero);
                    if (!altIsHeld)
                    {
                        keybd_event(VK_MENU, 0, 0, UIntPtr.Zero); // Alt down (and keep it down)
                        altIsHeld = true;
                    }
                    keybd_event(VK_TAB, 0, 0, UIntPtr.Zero); // Tab down
                    keybd_event(VK_TAB, 0, KEYEVENTF_KEYUP, UIntPtr.Zero); // Tab up (instant tap)
                    return (IntPtr)1; // Block original Tab
                }
                else if (isKeyUp)
                {
                    // Don't release Alt here - keep it held for cycling
                    return (IntPtr)1; // Block original Tab
                }
            }

            // Handle F4 for Windows Key
            if (vkCode == VK_F4)
            {
                if (isKeyDown)
                {
                    keybd_event(VK_LWIN, 0, 0, UIntPtr.Zero); // Win down
                    keybd_event(VK_LWIN, 0, KEYEVENTF_KEYUP, UIntPtr.Zero); // Win up
                    return (IntPtr)1; // Block original F4
                }
                else if (isKeyUp)
                {
                    return (IntPtr)1; // Block original F4
                }
            }
        }

        return CallNextHookEx(_hookID, nCode, wParam, lParam);
    }
}