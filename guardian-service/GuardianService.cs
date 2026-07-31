using System;
using System.IO;
using System.Net;
using System.Text;
using System.Diagnostics;
using System.Threading;
using System.ServiceProcess;
using System.Collections.Generic;
using System.Text.RegularExpressions;

namespace AmnShield
{
    public class GuardianService : ServiceBase
    {
        public const string ServiceNameId = "AmnShieldGuardian";
        private const string ConfigDir = @"C:\ProgramData\AmnShield";
        private const string ConfigPath = @"C:\ProgramData\AmnShield\config.json";
        private const string HostsPath = @"C:\Windows\System32\drivers\etc\hosts";
        
        private Thread _workerThread;
        private bool _isRunning;
        private FileSystemWatcher _watcher;
        private HttpListener _httpListener;
        private readonly object _lock = new object();
        
        // Active configurations
        private List<string> _bannedApps = new List<string>();
        private List<string> _bannedDomains = new List<string>();
        private bool _focusModeActive = false;

        // Strict system processes whitelist (forbidden to kill)
        private readonly HashSet<string> _systemWhitelist = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
        {
            "explorer", "taskmgr", "svchost", "lsass", "services", "winlogon", 
            "csrss", "smss", "wininit", "spoolsv", "dwm", "runtimebroker", 
            "taskhostw", "taskhost", "searchindexer", "searchhost", "searchapp",
            "ctfmon", "conhost", "cmd", "powershell", "pwsh", "sihost", "fontdrvhost",
            "system", "idle", "audiodg", "memory compression", "registry",
            "aggregatorhost", "applicationframehost", "shellexperiencehost", "shellhost",
            "startmenuexperiencehost", "textinputhost", "useroobebroker", "systemsettings",
            "lockapp", "tabtip", "dllhost", "unsecapp", "wlanext", "wmiprvse",
            "wmiregistrationservice", "lsaiso", "ngciso", "secure system",
            "widgets", "widgetservice", "widgetboard", "wsl", "wslhost", "wslservice",
            "vmmem", "vmcompute", "vmms",
            "winget", "windowspackagemanagerserver", "winstore.app", "winappruntime",
            "storedesktopextension", "storeexperiencehost", "purchasedesktopextension",
            "storestub",
            "phoneexperiencehost", "crossdeviceservice", "crossdeviceresume",
            "crossdevicesettingshost", "crossdevicestreaminghost", "crossdevicefileshost",
            "crossdevicesharehost", "filesynchelper", "filecoauth", "onedrive.sync.service",
            "offloaditemservice",
            "msmpeng", "nissrv", "securityhealthservice", "securityhealthsystray",
            "sechealthui", "smartscreen", "sense", "mpdefendercoreservice",
            "control", "regedit", "mmc", "msconfig", "perfmon", "resmon", 
            "cleanmgr", "dfrgui", "mdsched", "iscsicpl", "odbcad32", 
            "recoverydrive", "osrecoveryagent", "postonce", "msinfo32", "psr", 
            "mstsc", "charmap", "magnify", "narrator", "osk", "voiceaccess", 
            "livecaptions", "appverif", "appcertui", "gpuview", "wpa", "wprui",
            "dell.coreservices.client", "dell.remediation.agent", "dell.techhub",
            "dell.techhub.analytics.subagent", "dell.techhub.datamanager.subagent",
            "dell.techhub.diagnostics.subagent", "dell.techhub.instrumentation.subagent",
            "dell.techhub.instrumentation.userprocess", "dell.uca.manager", "dell.update.subagent",
            "dellsupportassistremediationservice", "supportassistagent", "dcu-cli",
            "bootpartitionmgmt", "deployer", "dellsupportassistcontrolpanel",
            "intelaudioservice", "inteldisplayumservice", "intelgraphicssoftware.service",
            "ipf_helper", "ipf_uf", "ipfsvc", "wavesaudioservice", "wavessysvc64",
            "rtkauduservice64", "rtkngui64", "rtkaudioservice", "igfxhk", "igfxtray", "hkcmd",
            "tokenbroker", "webaccountmanager", "msa", "credprov", "microsoftaccount", "accountsd",
            "rg", "ripgrep", "esbuild", "tsgo", "rcedit", "winpty-agent", "openconsole", "vsce-sign",
            "amnshield_flutter", "amnshieldguardian", "flutter", "dart", "dartaotruntime",
            "dartvm", "node", "git", "adb", "language_server_windows_x64", "elevation_service",
            "identity_helper"
        };

        public GuardianService()
        {
            this.ServiceName = ServiceNameId;
            this.CanStop = true;
            this.CanPauseAndContinue = false;
            this.AutoLog = true;
        }

        protected override void OnStart(string[] args)
        {
            _isRunning = true;
            
            // Ensure Config directory exists
            if (!Directory.Exists(ConfigDir))
            {
                Directory.CreateDirectory(ConfigDir);
            }

            // Load initial config
            LoadConfiguration();

            // Set up Config file watcher
            SetupFileWatcher();

            // Start HTTP API Status Server for browser extension sync
            StartHttpApiServer();

            // Start worker thread
            _workerThread = new Thread(MonitorLoop)
            {
                IsBackground = true,
                Priority = ThreadPriority.BelowNormal
            };
            _workerThread.Start();
        }

        protected override void OnStop()
        {
            _isRunning = false;
            if (_watcher != null)
            {
                _watcher.EnableRaisingEvents = false;
                _watcher.Dispose();
            }

            if (_httpListener != null && _httpListener.IsListening)
            {
                try { _httpListener.Stop(); } catch { }
            }

            // Cleanup hosts file blocks when stopping service
            lock (_lock)
            {
                UpdateHostsFile(new List<string>());
            }
        }

        private void StartHttpApiServer()
        {
            try
            {
                _httpListener = new HttpListener();
                _httpListener.Prefixes.Add("http://127.0.0.1:48192/");
                _httpListener.Start();

                ThreadPool.QueueUserWorkItem((state) =>
                {
                    while (_isRunning && _httpListener != null && _httpListener.IsListening)
                    {
                        try
                        {
                            var ctx = _httpListener.GetContext();
                            ThreadPool.QueueUserWorkItem((_) => ProcessHttpRequest(ctx));
                        }
                        catch
                        {
                            // Catch shutdown errors silently
                        }
                    }
                });
            }
            catch (Exception ex)
            {
                EventLog.WriteEntry(string.Format("HTTP API Server Error: {0}", ex.Message), EventLogEntryType.Warning);
            }
        }

        private void ProcessHttpRequest(HttpListenerContext ctx)
        {
            try
            {
                ctx.Response.Headers.Add("Access-Control-Allow-Origin", "*");
                ctx.Response.Headers.Add("Access-Control-Allow-Methods", "GET, OPTIONS, POST");
                ctx.Response.Headers.Add("Access-Control-Allow-Headers", "Content-Type");

                if (ctx.Request.HttpMethod == "OPTIONS")
                {
                    ctx.Response.StatusCode = 204;
                    ctx.Response.Close();
                    return;
                }

                bool focus;
                int bannedAppsCount;
                List<string> domainsCopy;

                lock (_lock)
                {
                    focus = _focusModeActive;
                    bannedAppsCount = _bannedApps.Count;
                    domainsCopy = new List<string>(_bannedDomains);
                }

                var sb = new StringBuilder();
                sb.Append("{\"status\":\"online\",");
                sb.AppendFormat("\"focus_mode_active\":{0},", focus ? "true" : "false");
                sb.AppendFormat("\"banned_apps_count\":{0},", bannedAppsCount);
                sb.AppendFormat("\"banned_domains_count\":{0},", domainsCopy.Count);
                sb.Append("\"banned_domains\":[");
                for (int i = 0; i < domainsCopy.Count; i++)
                {
                    sb.AppendFormat("\"{0}\"", domainsCopy[i].Replace("\\", "\\\\").Replace("\"", "\\\""));
                    if (i < domainsCopy.Count - 1) sb.Append(",");
                }
                sb.Append("]}");

                string responseJson = sb.ToString();

                byte[] buffer = Encoding.UTF8.GetBytes(responseJson);
                ctx.Response.ContentType = "application/json";
                ctx.Response.ContentLength64 = buffer.Length;
                ctx.Response.OutputStream.Write(buffer, 0, buffer.Length);
                ctx.Response.OutputStream.Close();
            }
            catch
            {
                // Ignore disconnect exceptions
            }
        }

        private void SetupFileWatcher()
        {
            try
            {
                _watcher = new FileSystemWatcher(ConfigDir, "config.json")
                {
                    NotifyFilter = NotifyFilters.LastWrite | NotifyFilters.FileName | NotifyFilters.Size,
                    EnableRaisingEvents = true
                };
                
                _watcher.Changed += (s, e) => LoadConfiguration();
                _watcher.Created += (s, e) => LoadConfiguration();
            }
            catch (Exception ex)
            {
                EventLog.WriteEntry(string.Format("Watcher Error: {0}", ex.Message), EventLogEntryType.Warning);
            }
        }

        private void LoadConfiguration()
        {
            // Small delay to ensure writer has released file lock
            Thread.Sleep(200);
            
            lock (_lock)
            {
                if (!File.Exists(ConfigPath))
                {
                    return;
                }

                try
                {
                    string json = File.ReadAllText(ConfigPath);
                    
                    // Simple Regex-based JSON parsers (no Newtonsoft dependency needed)
                    _bannedApps = ParseJsonArray(json, "banned_apps");
                    _bannedDomains = ParseJsonArray(json, "banned_domains");
                    _focusModeActive = ParseJsonBool(json, "focus_mode_active");

                    // Apply domain redirects (only if master shield is active)
                    UpdateHostsFile(_focusModeActive ? _bannedDomains : new List<string>());
                }
                catch (Exception ex)
                {
                    EventLog.WriteEntry(string.Format("Load Config Error: {0}", ex.Message), EventLogEntryType.Error);
                }
            }
        }

        private List<string> ParseJsonArray(string json, string key)
        {
            var list = new List<string>();
            // Matches: "key"\s*:\s*\[([^\]]*)\]
            Match match = Regex.Match(json, string.Format("\"{0}\"\\s*:\\s*\\[([^\\]]*)\\]", key), RegexOptions.IgnoreCase);
            if (match.Success)
            {
                string rawArray = match.Groups[1].Value;
                // Matches items inside array
                foreach (Match itemMatch in Regex.Matches(rawArray, "\"([^\"]+)\""))
                {
                    string item = itemMatch.Groups[1].Value.Trim();
                    if (!string.IsNullOrEmpty(item))
                    {
                        list.Add(item);
                    }
                }
            }
            return list;
        }

        private bool ParseJsonBool(string json, string key)
        {
            Match match = Regex.Match(json, string.Format("\"{0}\"\\s*:\\s*(true|false)", key), RegexOptions.IgnoreCase);
            return match.Success && string.Equals(match.Groups[1].Value, "true", StringComparison.OrdinalIgnoreCase);
        }

        private void UpdateHostsFile(List<string> domains)
        {
            try
            {
                if (!File.Exists(HostsPath)) return;

                // Read existing hosts lines
                string[] lines = File.ReadAllLines(HostsPath);
                var cleanLines = new List<string>();
                bool inBlockSection = false;

                foreach (var line in lines)
                {
                    if (line.Contains("# AmnShield Blocklist Start"))
                    {
                        inBlockSection = true;
                        continue;
                    }
                    if (line.Contains("# AmnShield Blocklist End"))
                    {
                        inBlockSection = false;
                        continue;
                    }
                    if (!inBlockSection)
                    {
                        cleanLines.Add(line);
                    }
                }

                // If we have active domains to block, append them
                if (domains.Count > 0)
                {
                    cleanLines.Add("# AmnShield Blocklist Start");
                    foreach (var domain in domains)
                    {
                        string cleanDomain = domain.Trim().ToLower();
                        if (!string.IsNullOrEmpty(cleanDomain))
                        {
                            cleanLines.Add(string.Format("127.0.0.1 {0}", cleanDomain));
                            cleanLines.Add(string.Format("127.0.0.1 www.{0}", cleanDomain));
                        }
                    }
                    cleanLines.Add("# AmnShield Blocklist End");
                }

                // Write back to hosts file safely
                File.WriteAllLines(HostsPath, cleanLines.ToArray());
                FlushDnsCache();
            }
            catch (Exception ex)
            {
                EventLog.WriteEntry(string.Format("Hosts Update Error: {0}", ex.Message), EventLogEntryType.Warning);
            }
        }

        private void FlushDnsCache()
        {
            try
            {
                var psi = new ProcessStartInfo("ipconfig", "/flushdns")
                {
                    CreateNoWindow = true,
                    UseShellExecute = false
                };
                Process.Start(psi);
            }
            catch { }
        }

        private void MonitorLoop()
        {
            while (_isRunning)
            {
                try
                {
                    List<string> currentBannedApps;
                    bool active;
                    lock (_lock)
                    {
                        currentBannedApps = new List<string>(_bannedApps);
                        active = _focusModeActive;
                    }

                    if (active && currentBannedApps.Count > 0)
                    {
                        Process[] processes = Process.GetProcesses();
                        foreach (var process in processes)
                        {
                            try
                            {
                                string name = process.ProcessName;
                                
                                // Skip whitelist system processes
                                if (_systemWhitelist.Contains(name))
                                {
                                    continue;
                                }

                                 // Check if app name matches the blocklist (Exact or UWP Store App prefix match)
                                 bool isBanned = false;
                                 foreach (var banned in currentBannedApps)
                                 {
                                     string cleanBanned = banned.Replace(".exe", "").Trim();
                                     if (string.IsNullOrEmpty(cleanBanned)) continue;

                                     if (string.Equals(name, cleanBanned, StringComparison.OrdinalIgnoreCase) ||
                                         (cleanBanned.Length >= 3 && name.StartsWith(cleanBanned, StringComparison.OrdinalIgnoreCase)) ||
                                         (name.Length >= 3 && cleanBanned.StartsWith(name, StringComparison.OrdinalIgnoreCase)))
                                     {
                                         isBanned = true;
                                         break;
                                     }
                                 }

                                if (isBanned)
                                {
                                    process.Kill();
                                    EventLog.WriteEntry(string.Format("Terminated blocked application: {0}.exe", name), EventLogEntryType.Information);
                                }
                            }
                            catch
                            {
                                // Ignore process exit or access denied errors
                            }
                        }
                    }
                }
                catch (Exception ex)
                {
                    EventLog.WriteEntry(string.Format("Monitor Error: {0}", ex.Message), EventLogEntryType.Warning);
                }

                // Run monitor check every 1 second
                Thread.Sleep(1000);
            }
        }

        public static void Main()
        {
            ServiceBase.Run(new GuardianService());
        }
    }
}
