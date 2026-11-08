using Deliverance.Model.Enums;
using QuestPDF.Fluent;
using QuestPDF.Helpers;
using QuestPDF.Infrastructure;
using static Deliverance.Services.Pdf.PdfLayout;

namespace Deliverance.Services.Pdf
{
    internal record DeviceHealthRow(string Device, string Office, string? Type, int ReportsLast30Days,
        int OpenReports, DateTime? LastReport, DateTime? LastFix, float? NeedsFixProbability, IssueEnum? LikelyIssue);

    internal record DeviceLogLine(DateTime Date, string? Text);

    // Every device ranked by how likely it is to need a fix, with the logs behind the top ones.
    internal static class DeviceHealthDocument
    {
        public const float NeedsFixThreshold = 0.5f;

        // Every date passed in is already in display time.
        public static byte[] Generate(List<DeviceHealthRow> rows, Dictionary<string, List<DeviceLogLine>> topDeviceLogs,
            string? officeName, DateTime generatedAt)
        {
            var subtitle = officeName ?? "All offices";

            return Document.Create(document => document.Page(page =>
                ComposePage(page, "Device health", subtitle, generatedAt,
                    content => ComposeContent(content, rows, topDeviceLogs), landscape: true)))
                .GeneratePdf();
        }

        private static void ComposeContent(IContainer container, List<DeviceHealthRow> rows,
            Dictionary<string, List<DeviceLogLine>> topDeviceLogs)
        {
            container.Column(col =>
            {
                col.Item().Element(c => StatTiles(c,
                    ("Devices", rows.Count.ToString()),
                    ("With open reports", rows.Count(r => r.OpenReports > 0).ToString()),
                    ("Open reports", rows.Sum(r => r.OpenReports).ToString()),
                    ($"Likely to need a fix ({NeedsFixThreshold:P0}+)",
                        rows.Count(r => r.NeedsFixProbability >= NeedsFixThreshold).ToString())));

                if (rows.Count == 0)
                {
                    col.Item().PaddingTop(20).Text("There are no devices to report on.");
                    return;
                }

                col.Section("Devices by risk", c => c.Column(section =>
                {
                    section.Item().Text("Risk is the recommendation model's chance that the device gets a fault reported in the next 14 days.")
                        .FontColor(Colors.Grey.Darken2);
                    section.Item().PaddingTop(4).Element(t => ComposeDeviceTable(t, rows));
                }));

                if (topDeviceLogs.Count > 0)
                {
                    col.Section("Recent logs of the riskiest devices", c => c.Column(section =>
                    {
                        foreach (var (device, logs) in topDeviceLogs)
                        {
                            // A device's few lines stay on one page with its name.
                            section.Item().PaddingTop(6).ShowEntire().Column(block =>
                            {
                                block.Item().Text(device).SemiBold();
                                if (logs.Count == 0)
                                {
                                    block.Item().Text("No log lines in the last 7 days.").FontColor(Colors.Grey.Darken2);
                                }
                                foreach (var log in logs)
                                {
                                    block.Item().Text($"{log.Date:yyyy-MM-dd HH:mm}  {log.Text}");
                                }
                            });
                        }
                    }));
                }
            });
        }

        private static void ComposeDeviceTable(IContainer container, List<DeviceHealthRow> rows)
        {
            container.Table(table =>
            {
                table.ColumnsDefinition(columns =>
                {
                    columns.RelativeColumn(2);
                    columns.RelativeColumn(2);
                    columns.RelativeColumn();
                    columns.ConstantColumn(65);
                    columns.ConstantColumn(45);
                    columns.ConstantColumn(65);
                    columns.ConstantColumn(65);
                    columns.ConstantColumn(45);
                    columns.ConstantColumn(65);
                });
                table.Header(header =>
                {
                    foreach (var title in new[] { "Device", "Office", "Type", "Reports (30 d)", "Open", "Last report", "Last fix", "Risk", "Likely issue" })
                    {
                        header.Cell().Element(HeaderCell).Text(title).SemiBold();
                    }
                });
                foreach (var row in rows)
                {
                    var isRisky = row.NeedsFixProbability >= NeedsFixThreshold;

                    table.Cell().Element(BodyCell).Text(row.Device);
                    table.Cell().Element(BodyCell).Text(row.Office);
                    table.Cell().Element(BodyCell).Text(row.Type ?? "-");
                    table.Cell().Element(BodyCell).AlignRight().Text(row.ReportsLast30Days.ToString());
                    table.Cell().Element(BodyCell).AlignRight().Text(row.OpenReports.ToString());
                    table.Cell().Element(BodyCell).Text(FormatDate(row.LastReport));
                    table.Cell().Element(BodyCell).Text(FormatDate(row.LastFix));
                    var risk = table.Cell().Element(BodyCell).AlignRight()
                        .Text(row.NeedsFixProbability == null ? "-" : $"{row.NeedsFixProbability * 100:0}%");
                    if (isRisky) risk.SemiBold().FontColor(Colors.Red.Darken2);
                    // The likely issue only means something when the device is likely to have one.
                    table.Cell().Element(BodyCell).Text(isRisky ? row.LikelyIssue?.ToString() ?? "-" : "-");
                }
            });
        }
    }
}
