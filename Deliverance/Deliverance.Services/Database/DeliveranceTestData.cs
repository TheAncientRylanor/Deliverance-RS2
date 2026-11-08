using Deliverance.Services.ReportStateMachine;
using Deliverance.Model.Enums;
using Microsoft.EntityFrameworkCore;

namespace Deliverance.Services.Database
{
    public partial class DeliveranceDbContext : DbContext
    {
        private const string TestDataPrefix = "TEST ";

        private static readonly string[] MemoryLogs =
        [
            "low memory warning, memory usage at {0}%",
            "Resource-Exhaustion-Detector: virtual memory is low, chrome.exe is using the most memory",
            "out of memory error in outlook.exe",
            "page file usage high, system is paging heavily",
            "application terminated because of insufficient memory",
        ];
        private static readonly string[] DiskLogs =
        [
            "SMART warning: reallocated sector count rising on disk 0",
            "disk read error on Harddisk0, I/O retry succeeded",
            "bad block detected on disk 0",
            "disk queue length high, slow I/O on volume C:",
            "NTFS file system error, repair required on volume C:",
        ];
        private static readonly string[] OverheatingLogs =
        [
            "CPU temperature {0} C, thermal throttling active",
            "fan speed below threshold, fan failure warning",
            "thermal warning from ACPI, temperature above limit",
            "system overheated, CPU frequency reduced",
        ];
        private static readonly string[] DriverLogs =
        [
            "display driver stopped responding and has recovered",
            "network adapter driver crash, adapter reset",
            "driver update failed with error 0x80070103",
            "audio driver service stopped unexpectedly",
            "bugcheck DRIVER_IRQL_NOT_LESS_OR_EQUAL in network driver",
        ];
        private static readonly string[] OsLogs =
        [
            "Windows update failed with error 0x800f081f",
            "system file corruption found by sfc scan",
            "service wuauserv stopped unexpectedly",
            "boot configuration error, startup repair started",
            "user profile service failed to load the profile",
        ];
        private static readonly string[] RoutineLogs =
        [
            "heartbeat ok",
            "scheduled backup completed",
            "antivirus definitions updated",
            "no pending updates",
            "user session started",
            "scheduled cleanup completed",
        ];

        private record TestDeviceProfile(int DeviceCount, IssueEnum? Issue, string[] FaultLogs,
            string[] ReportDetails, string[] ClearComments);

        private static readonly TestDeviceProfile[] TestDeviceProfiles =
        [
            new(18, null, [],
                ["Keyboard key stuck", "Asked for a new mouse", "Monitor cable was loose", "Slow login this morning"],
                ["Fixed on site.", "No fault found."]),
            new(9, IssueEnum.Hardware, MemoryLogs,
                ["Very slow with several apps open", "Apps close by themselves", "Freezes when opening large files"],
                ["Memory was full, upgraded the RAM.", "Added another RAM module."]),
            new(8, IssueEnum.Hardware, DiskLogs,
                ["Files take very long to open", "Clicking noise from the computer", "Could not save a document"],
                ["Replaced the failing disk.", "Disk had bad sectors, cloned to a new one."]),
            new(8, IssueEnum.Hardware, OverheatingLogs,
                ["Fan is very loud", "Shuts down under load", "Case is hot to the touch"],
                ["Cleaned the fan and replaced the thermal paste.", "Replaced the broken fan."]),
            new(7, IssueEnum.Software, DriverLogs,
                ["Screen flickers and goes black", "Network keeps disconnecting", "No sound after restart"],
                ["Reinstalled the driver.", "Rolled the driver back to the previous version."]),
            new(6, IssueEnum.Software, OsLogs,
                ["Updates keep failing", "Takes minutes to start", "Could not log in to my profile"],
                ["Repaired the system files.", "Reinstalled the operating system."]),
            new(4, IssueEnum.Both, [.. DiskLogs, .. OsLogs],
                ["Crashes and will not start normally", "Files are missing and updates fail"],
                ["Replaced the disk and reinstalled the operating system."]),
        ];

        public async Task<bool> SeedTestDataAsync()
        {
            if (await Offices.AnyAsync(x => x.Name.StartsWith(TestDataPrefix)))
            {
                return false;
            }
            var admin = await Users.FirstOrDefaultAsync(x => x.RoleId == RoleEnum.Admin)
                ?? throw new InvalidOperationException("Test data needs an admin user.");
            var regularUser = await Users.FirstOrDefaultAsync(x => x.RoleId == RoleEnum.User) ?? admin;

            var rnd = new Random(42);
            var clearRnd = new Random(43);
            var now = DateTime.UtcNow;

            var profiles = TestDeviceProfiles
                .SelectMany(x => Enumerable.Repeat(x, x.DeviceCount))
                .ToArray();
            rnd.Shuffle(profiles);

            string[] officeNames = ["Sarajevo", "Mostar", "Tuzla", "Zenica", "Banja Luka"];
            var devicesPerOffice = profiles.Length / officeNames.Length;
            var offices = new List<Office>();
            var reports = new List<Report>();

            for (var o = 0; o < officeNames.Length; o++)
            {
                var office = new Office
                {
                    Name = TestDataPrefix + officeNames[o],
                    CreatedAt = now.AddDays(-400),
                    UserUUID = admin.UUID,
                };
                offices.Add(office);

                for (var d = 0; d < devicesPerOffice; d++)
                {
                    var index = o * devicesPerOffice + d;
                    var device = CreateTestDevice(office, o, d, index, rnd, now);
                    office.Devices.Add(device);

                    if (index % 4 != 3)
                    {
                        device.Scout = new Scout
                        {
                            CreatedAt = now.AddDays(-390),
                            IsDisabled = index % 20 == 0,
                        };
                    }

                    var deviceReports = CreateTestReports(office, device, profiles[index], admin, regularUser.UUID, rnd, clearRnd, now);
                    reports.AddRange(deviceReports);
                    if (device.Scout != null)
                    {
                        AddTestLogs(device.Scout, profiles[index], deviceReports, rnd, now);
                    }
                }
                office.NumOfDevices = office.Devices.Count;
                office.NumOfScouts = office.Devices.Count(x => x.Scout != null);
            }
            for (var i = 0; i < reports.Count; i++)
            {
                reports[i].ReportName = $"{TestDataPrefix}Report {i + 1:D4}";
            }

            await using var transaction = await Database.BeginTransactionAsync();
            Offices.AddRange(offices);
            Reports.AddRange(reports);
            await SaveChangesAsync();

            ReportStatistics.AddRange(
                from report in reports
                from officeReport in report.OfficeReports
                from deviceReport in officeReport.DeviceReports
                select new ReportStatistics
                {
                    ReportId = report.Id,
                    OfficeReportId = officeReport.Id,
                    OfficeId = officeReport.OfficeId,
                    DeviceId = deviceReport.DeviceId,
                    DateReported = report.DateReported,
                    UserId = report.UserUUID,
                });
            await SaveChangesAsync();
            await transaction.CommitAsync();
            return true;
        }

        private static Device CreateTestDevice(Office office, int officeIndex, int deviceIndex, int index, Random rnd, DateTime now)
        {
            string[] types = ["Computer", "Computer", "Laptop", "Laptop", "Server"];
            string[] systems = ["Windows 11", "Windows 11", "Windows 10"];
            string[] manufacturers = ["Lenovo", "HP", "Dell"];
            var type = types[rnd.Next(types.Length)];

            return new Device
            {
                Name = $"{TestDataPrefix}{type} {index + 1:D2}",
                OfficeName = office.Name,
                CreatedAt = now.AddDays(-400),
                PositionX = 0.15 + 0.23 * (deviceIndex % 4),
                PositionY = 0.2 + 0.3 * (deviceIndex / 4),
                IconName = type.ToLower(),
                Type = type,
                IpAddress = $"10.0.{officeIndex + 1}.{deviceIndex + 10}",
                MacAddress = $"02:00:00:00:{officeIndex + 1:X2}:{deviceIndex + 10:X2}",
                SubnetMask = "255.255.255.0",
                VlanID = (officeIndex + 1).ToString(),
                OS = systems[rnd.Next(systems.Length)],
                Manufacturer = manufacturers[rnd.Next(manufacturers.Length)],
            };
        }

        public async Task<int> FillTestClearDetailsAsync()
        {
            var admin = await Users.FirstOrDefaultAsync(x => x.RoleId == RoleEnum.Admin)
                ?? throw new InvalidOperationException("Test data needs an admin user.");
            var reports = await Reports
                .Where(x => x.ReportName.StartsWith(TestDataPrefix)
                    && x.Status == nameof(ClearedReportState)
                    && x.DateCleared == null)
                .OrderBy(x => x.Id)
                .ToListAsync();

            var rnd = new Random(43);
            var now = DateTime.UtcNow;
            foreach (var report in reports)
            {
                SetTestClearDetails(report, admin.Username, rnd, now);
            }
            await SaveChangesAsync();
            return reports.Count;
        }

        private static void SetTestClearDetails(Report report, string adminName, Random rnd, DateTime now)
        {
            var maxHours = report.Severity >= SeverityEnum.Danger ? 24 : 120;
            var dateCleared = report.DateReported.AddHours(1 + rnd.NextDouble() * maxHours);
            report.DateCleared = dateCleared < now ? dateCleared : now;
            report.ReportClearedBy = adminName;
        }

        private static List<Report> CreateTestReports(Office office, Device device, TestDeviceProfile profile,
            User admin, Guid regularUserId, Random rnd, Random clearRnd, DateTime now)
        {
            var isHealthy = profile.Issue == null;
            var count = isHealthy ? rnd.Next(2, 7) : rnd.Next(22, 33);
            var reports = new List<Report>();

            for (var i = 0; i < count; i++)
            {
                var ageInDays = rnd.NextDouble() * 365;
                var detail = profile.ReportDetails[rnd.Next(profile.ReportDetails.Length)];
                var status = PickTestReportStatus(ageInDays, rnd);

                var report = new Report
                {
                    Status = status,
                    DateReported = now.AddDays(-ageInDays),
                    Severity = (SeverityEnum)rnd.Next(isHealthy ? 1 : 3, isHealthy ? 4 : 6),
                    IssueType = rnd.NextDouble() < 0.05 ? null : profile.Issue ?? (IssueEnum)rnd.Next(1, 4),
                    Detail = detail,
                    UserUUID = rnd.NextDouble() < 0.7 ? regularUserId : admin.UUID,
                    Comment = status == nameof(ClearedReportState)
                        ? profile.ClearComments[rnd.Next(profile.ClearComments.Length)]
                        : null,
                    OfficeReports =
                    {
                        new OfficeReport
                        {
                            Office = office,
                            NumReportedDevices = 1,
                            DeviceReports = { new DeviceReport { Device = device, Detail = detail } },
                        },
                    },
                };
                if (status == nameof(ClearedReportState))
                {
                    SetTestClearDetails(report, admin.Username, clearRnd, now);
                }
                reports.Add(report);
            }
            return reports;
        }

        private static string PickTestReportStatus(double ageInDays, Random rnd)
        {
            var roll = rnd.NextDouble();
            if (roll < 0.02) return nameof(DraftReportState);
            if (ageInDays > 30 || roll < 0.4) return nameof(ClearedReportState);
            return roll < 0.7 ? nameof(SeenReportState) : nameof(UnseenReportState);
        }

        private static void AddTestLogs(Scout scout, TestDeviceProfile profile, List<Report> reports, Random rnd, DateTime now)
        {
            string[][] faultPools = [MemoryLogs, DiskLogs, OverheatingLogs, DriverLogs, OsLogs];

            for (var day = 0; day < 365; day++)
            {
                var pool = rnd.NextDouble() < 0.02 ? faultPools[rnd.Next(faultPools.Length)] : RoutineLogs;
                AddTestLog(scout, pool, now.AddDays(-day - rnd.NextDouble()), rnd);
            }

            if (profile.Issue == null)
            {
                return;
            }

            foreach (var report in reports)
            {
                var lines = rnd.Next(3, 6);
                for (var i = 0; i < lines; i++)
                {
                    AddTestLog(scout, profile.FaultLogs, report.DateReported.AddDays(-1 - rnd.NextDouble() * 5), rnd);
                }
            }

            if (rnd.NextDouble() < 0.75)
            {
                for (var i = 0; i < 6; i++)
                {
                    AddTestLog(scout, profile.FaultLogs, now.AddDays(-rnd.NextDouble() * 6), rnd);
                }
            }
        }

        private static void AddTestLog(Scout scout, string[] pool, DateTime date, Random rnd)
        {
            var line = pool[rnd.Next(pool.Length)];
            scout.DeviceLogs.Add(new DeviceLog
            {
                DateLogged = date,
                Log = string.Format(line, rnd.Next(85, 100)),
            });
        }
    }
}
