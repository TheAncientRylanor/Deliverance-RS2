using Deliverance.Model.Enums;
using Deliverance.Services.Configuration;
using QuestPDF.Fluent;
using QuestPDF.Infrastructure;
using static Deliverance.Services.Pdf.PdfLayout;

namespace Deliverance.Services.Pdf
{
    // What was reported in a period: totals, breakdowns, time to clear and the full list.
    internal static class ReportActivityDocument
    {
        private const int TopDevicesLimit = 10;

        // Dates come in as UTC; durations are worked out in UTC and only shown times are converted.
        public static byte[] Generate(List<Report> reports, DateTime from, DateTime to,
            int? officeId, string? officeName, DisplayTimeZone displayTimeZone)
        {
            var subtitle = $"{displayTimeZone.FromUtc(from):yyyy-MM-dd HH:mm} to {displayTimeZone.FromUtc(to):yyyy-MM-dd HH:mm}"
                + $" · {officeName ?? "All offices"}";

            return Document.Create(document => document.Page(page =>
                ComposePage(page, "Report activity", subtitle, displayTimeZone.Now,
                    content => ComposeContent(content, reports, officeId, displayTimeZone))))
                .GeneratePdf();
        }

        private static void ComposeContent(IContainer container, List<Report> reports, int? officeId,
            DisplayTimeZone displayTimeZone)
        {
            var cleared = reports.Where(r => r.Status == nameof(ClearedReportState)).ToList();
            var timesToClear = cleared
                .Where(r => r.DateCleared != null && r.DateCleared >= r.DateReported)
                .Select(r => (r.Severity, Duration: r.DateCleared!.Value - r.DateReported))
                .ToList();

            container.Column(col =>
            {
                col.Item().Element(c => StatTiles(c,
                    ("Reports", reports.Count.ToString()),
                    ("Open", (reports.Count - cleared.Count).ToString()),
                    ("Cleared", cleared.Count.ToString()),
                    ("Average time to clear", timesToClear.Count == 0
                        ? "-"
                        : FormatDuration(Average(timesToClear.Select(x => x.Duration))))));

                if (reports.Count == 0)
                {
                    col.Item().PaddingTop(20).Text("No reports were sent in this period.");
                    return;
                }

                col.Section("By status", c => BarTable(c,
                [
                    ("Unseen", reports.Count(r => r.Status == nameof(UnseenReportState))),
                    ("Seen", reports.Count(r => r.Status == nameof(SeenReportState))),
                    ("Cleared", cleared.Count),
                ]));

                col.Section("By severity", c => BarTable(c, CountByEnum(reports, r => r.Severity)));

                col.Section("By issue type", c => BarTable(c, CountByEnum(reports, r => r.IssueType)));

                // With one office picked, this would be a single bar.
                if (officeId == null)
                {
                    col.Section("By office", c => BarTable(c, reports
                        .SelectMany(r => r.OfficeReports.Select(o => o.Office?.Name ?? "-").Distinct())
                        .GroupBy(name => name)
                        .Select(g => (g.Key, g.Count()))
                        .OrderByDescending(x => x.Item2)
                        .ToList()));
                }

                col.Section("Most reported devices", c => ComposeTopDevices(c, reports, officeId));

                col.Section("Average time to clear by severity", c => ComposeTimeToClear(c, timesToClear));

                col.Section("Reports", c => ComposeReportList(c, reports, displayTimeZone));
            });
        }

        // Every value of the enum in order, plus "Not set" when some reports left it empty.
        private static List<(string, int)> CountByEnum<TEnum>(List<Report> reports, Func<Report, TEnum?> selector)
            where TEnum : struct, Enum
        {
            var counts = Enum.GetValues<TEnum>()
                .Select(value => (value.ToString(), reports.Count(r => selector(r)?.Equals(value) == true)))
                .ToList();
            var notSet = reports.Count(r => selector(r) == null);
            if (notSet > 0) counts.Add(("Not set", notSet));
            return counts;
        }

        private static void ComposeTopDevices(IContainer container, List<Report> reports, int? officeId)
        {
            // A report can name devices in several offices; only count the picked office's.
            var devices = reports
                .SelectMany(r => r.OfficeReports
                    .Where(o => officeId == null || o.OfficeId == officeId)
                    .SelectMany(o => o.DeviceReports.Select(d => (ReportId: r.Id, d.DeviceId,
                        Name: d.Device?.Name ?? "-", Office: o.Office?.Name ?? "-"))))
                .DistinctBy(x => (x.ReportId, x.DeviceId))
                .GroupBy(x => x.DeviceId)
                .Select(g => (g.First().Name, g.First().Office, Count: g.Count()))
                .OrderByDescending(x => x.Count)
                .Take(TopDevicesLimit)
                .ToList();

            container.Table(table =>
            {
                table.ColumnsDefinition(columns =>
                {
                    columns.RelativeColumn(2);
                    columns.RelativeColumn(2);
                    columns.ConstantColumn(60);
                });
                table.Header(header =>
                {
                    header.Cell().Element(HeaderCell).Text("Device").SemiBold();
                    header.Cell().Element(HeaderCell).Text("Office").SemiBold();
                    header.Cell().Element(HeaderCell).AlignRight().Text("Reports").SemiBold();
                });
                foreach (var (name, office, count) in devices)
                {
                    table.Cell().Element(BodyCell).Text(name);
                    table.Cell().Element(BodyCell).Text(office);
                    table.Cell().Element(BodyCell).AlignRight().Text(count.ToString());
                }
            });
        }

        private static void ComposeTimeToClear(IContainer container, List<(SeverityEnum? Severity, TimeSpan Duration)> times)
        {
            if (times.Count == 0)
            {
                container.Text("No report in this period has a recorded clear date.");
                return;
            }

            var rows = times
                .GroupBy(x => x.Severity)
                .OrderBy(g => g.Key == null ? int.MaxValue : (int)g.Key)
                .Select(g => (Severity: g.Key?.ToString() ?? "Not set", Count: g.Count(),
                    Average: Average(g.Select(x => x.Duration))))
                .ToList();

            container.Table(table =>
            {
                table.ColumnsDefinition(columns =>
                {
                    columns.RelativeColumn();
                    columns.RelativeColumn();
                    columns.RelativeColumn();
                });
                table.Header(header =>
                {
                    header.Cell().Element(HeaderCell).Text("Severity").SemiBold();
                    header.Cell().Element(HeaderCell).AlignRight().Text("Cleared").SemiBold();
                    header.Cell().Element(HeaderCell).AlignRight().Text("Average time to clear").SemiBold();
                });
                foreach (var (severity, count, average) in rows)
                {
                    table.Cell().Element(BodyCell).Text(severity);
                    table.Cell().Element(BodyCell).AlignRight().Text(count.ToString());
                    table.Cell().Element(BodyCell).AlignRight().Text(FormatDuration(average));
                }
            });
        }

        private static void ComposeReportList(IContainer container, List<Report> reports, DisplayTimeZone displayTimeZone)
        {
            container.DefaultTextStyle(x => x.FontSize(8)).Table(table =>
            {
                table.ColumnsDefinition(columns =>
                {
                    columns.ConstantColumn(55);
                    columns.RelativeColumn(2);
                    columns.RelativeColumn(1.5f);
                    columns.ConstantColumn(45);
                    columns.ConstantColumn(48);
                    columns.ConstantColumn(42);
                    columns.RelativeColumn();
                    columns.ConstantColumn(50);
                });
                table.Header(header =>
                {
                    foreach (var title in new[] { "Date", "Title", "Office", "Severity", "Issue", "Status", "Cleared by", "Time to clear" })
                    {
                        header.Cell().Element(HeaderCell).Text(title).SemiBold();
                    }
                });
                foreach (var report in reports)
                {
                    var timeToClear = report.DateCleared != null && report.DateCleared >= report.DateReported
                        ? FormatDuration(report.DateCleared.Value - report.DateReported)
                        : "-";

                    table.Cell().Element(BodyCell).Text(FormatDate(displayTimeZone.FromUtc(report.DateReported)));
                    table.Cell().Element(BodyCell).Text(report.ReportName);
                    table.Cell().Element(BodyCell).Text(string.Join("; ",
                        report.OfficeReports.Select(o => o.Office?.Name ?? "-").Distinct()));
                    table.Cell().Element(BodyCell).Text(report.Severity?.ToString() ?? "-");
                    table.Cell().Element(BodyCell).Text(report.IssueType?.ToString() ?? "-");
                    table.Cell().Element(BodyCell).Text(StatusLabel(report.Status));
                    table.Cell().Element(BodyCell).Text(report.ReportClearedBy ?? "-");
                    table.Cell().Element(BodyCell).Text(timeToClear);
                }
            });
        }

        private static TimeSpan Average(IEnumerable<TimeSpan> durations) =>
            TimeSpan.FromTicks((long)durations.Average(d => d.Ticks));
    }
}
