using System;
using System.Diagnostics;
using System.IO;
using System.Runtime.InteropServices;
using System.Text;

public static class FeriasDCEIniciar
{
    private static readonly object LogLock = new object();
    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    private static extern int MessageBox(IntPtr owner, string text, string caption, uint type);

    public static string QuoteArgument(string value)
    {
        StringBuilder result = new StringBuilder("\"");
        int slashes = 0;
        foreach (char c in value)
        {
            if (c == '\\') { slashes++; continue; }
            if (c == '"') { result.Append('\\', slashes * 2 + 1); result.Append(c); }
            else { result.Append('\\', slashes); result.Append(c); }
            slashes = 0;
        }
        result.Append('\\', slashes * 2); result.Append('"');
        return result.ToString();
    }

    public static ProcessStartInfo BuildStartInfo(string root, string windowsRoot)
    {
        ProcessStartInfo info = new ProcessStartInfo();
        info.FileName = Path.Combine(windowsRoot, @"System32\WindowsPowerShell\v1.0\powershell.exe");
        info.Arguments = "-NoLogo -NoProfile -NonInteractive -STA -File " + QuoteArgument(Path.Combine(root, "FeriasDCE.ps1"));
        info.WorkingDirectory = root;
        info.UseShellExecute = false;
        info.CreateNoWindow = true;
        info.WindowStyle = ProcessWindowStyle.Hidden;
        info.RedirectStandardOutput = true;
        info.RedirectStandardError = true;
        return info;
    }

    public static string CreateLog(string root, string fallbackRoot)
    {
        string name = "INICIALIZADOR_GRAFICO_" + DateTime.Now.ToString("yyyyMMdd_HHmmss_fff") + "_" + Guid.NewGuid().ToString("N") + ".log";
        foreach (string dir in new string[] { Path.Combine(root, "Logs"), fallbackRoot })
        {
            try
            {
                Directory.CreateDirectory(dir);
                string path = Path.Combine(dir, name);
                using (FileStream file = new FileStream(path, FileMode.CreateNew, FileAccess.Write, FileShare.Read)) { }
                return path;
            }
            catch (IOException) { }
            catch (UnauthorizedAccessException) { }
        }
        return null;
    }

    public static void WriteLog(string path, string text)
    {
        if (String.IsNullOrEmpty(path) || text == null) return;
        try
        {
            lock (LogLock)
                File.AppendAllText(path, "[" + DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss.fff") + "] " + text + Environment.NewLine, new UTF8Encoding(true));
        }
        catch (IOException) { }
        catch (UnauthorizedAccessException) { }
    }

    [STAThread]
    public static int Main()
    {
        string log = null;
        try
        {
            string root = AppDomain.CurrentDomain.BaseDirectory;
            log = CreateLog(root, Path.Combine(Path.GetTempPath(), "FeriasDCELogs"));
            string main = Path.Combine(root, "FeriasDCE.ps1");
            if (!File.Exists(main)) throw new FileNotFoundException("Coloque este inicializador na mesma pasta do FeriasDCE.ps1.", main);
            WriteLog(log, "Inicializador grafico HIST-R11; PowerShell STA sem console; politica de execucao vigente preservada.");
            WriteLog(log, "Pasta: " + root);
            using (Process process = new Process())
            {
                process.StartInfo = BuildStartInfo(root, Environment.GetFolderPath(Environment.SpecialFolder.Windows));
                process.OutputDataReceived += delegate(object sender, DataReceivedEventArgs e) { WriteLog(log, e.Data); };
                process.ErrorDataReceived += delegate(object sender, DataReceivedEventArgs e) { WriteLog(log, e.Data); };
                if (!process.Start()) throw new InvalidOperationException("Nao foi possivel iniciar o PowerShell.");
                process.BeginOutputReadLine(); process.BeginErrorReadLine();
                process.WaitForExit();
                int code = process.ExitCode;
                WriteLog(log, "Encerramento. Codigo: " + code);
                if (code != 0) ShowError("O sistema encerrou com codigo " + code + ".", log);
                return code;
            }
        }
        catch (Exception error)
        {
            WriteLog(log, error.ToString());
            ShowError(error.Message, log);
            return 1;
        }
    }

    private static void ShowError(string text, string log)
    {
        string detail = String.IsNullOrEmpty(log) ? "Nao foi possivel gravar o log." : "Log: " + log;
        MessageBox(IntPtr.Zero, text + Environment.NewLine + Environment.NewLine + detail, "Ferias DCE - inicializacao", 0x10);
    }
}
