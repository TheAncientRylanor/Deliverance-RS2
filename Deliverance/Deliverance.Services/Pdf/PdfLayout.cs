using QuestPDF.Fluent;
using QuestPDF.Helpers;
using QuestPDF.Infrastructure;

namespace Deliverance.Services.Pdf
{
    // Page frame and building blocks shared by both PDF reports.
    internal static class PdfLayout
    {
        public static void ComposePage(PageDescriptor page, string title, string subtitle, DateTime generatedAt,
            Action<IContainer> content, bool landscape = false)
        {
            page.Size(landscape ? PageSizes.A4.Landscape() : PageSizes.A4);
            page.Margin(30);
            page.PageColor(Colors.White);
            page.DefaultTextStyle(x => x.FontSize(9));

            page.Header().Column(col =>
            {
                col.Item().Text("Deliverance").FontSize(9).FontColor(Colors.Grey.Darken1);
                col.Item().Text(title).FontSize(18).SemiBold().FontColor(Colors.Blue.Darken3);
                col.Item().Text(subtitle).FontColor(Colors.Grey.Darken2);
                col.Item().PaddingTop(6).LineHorizontal(1).LineColor(Colors.Grey.Lighten1);
            });

            page.Content().PaddingVertical(10).Element(content);

            page.Footer().Row(row =>
            {
                row.RelativeItem().Text($"Generated {generatedAt:yyyy-MM-dd HH:mm}").FontColor(Colors.Grey.Darken1);
                row.RelativeItem().AlignRight().Text(text =>
                {
                    text.Span("Page ");
                    text.CurrentPageNumber();
                    text.Span(" of ");
                    text.TotalPages();
                });
            });
        }

        // The heading moves to the next page with its content instead of being left alone at the bottom.
        public static void Section(this ColumnDescriptor col, string title, Action<IContainer> content) =>
            col.Item().PaddingTop(12).EnsureSpace(80).Column(section =>
            {
                section.Item().PaddingBottom(4).Text(title).FontSize(13).SemiBold();
                section.Item().Element(content);
            });

        public static void StatTiles(IContainer container, params (string Label, string Value)[] stats) =>
            container.Row(row =>
            {
                row.Spacing(8);
                foreach (var (label, value) in stats)
                {
                    row.RelativeItem()
                        .Border(1).BorderColor(Colors.Grey.Lighten2)
                        .Background(Colors.Grey.Lighten4)
                        .Padding(8)
                        .Column(c =>
                        {
                            c.Item().Text(value).FontSize(16).SemiBold();
                            c.Item().Text(label).FontColor(Colors.Grey.Darken2);
                        });
                }
            });

        // QuestPDF has no charts, so each count gets a bar drawn as a filled box.
        public static void BarTable(IContainer container, IReadOnlyList<(string Label, int Count)> items)
        {
            var max = items.Count == 0 ? 0 : items.Max(x => x.Count);
            container.Table(table =>
            {
                table.ColumnsDefinition(columns =>
                {
                    columns.ConstantColumn(120);
                    columns.ConstantColumn(45);
                    columns.RelativeColumn();
                });
                foreach (var (label, count) in items)
                {
                    table.Cell().PaddingVertical(2).Text(label);
                    table.Cell().PaddingVertical(2).PaddingRight(8).AlignRight().Text(count.ToString());
                    var bar = table.Cell().PaddingVertical(4);
                    if (max > 0)
                    {
                        bar.Row(row =>
                        {
                            if (count > 0) row.RelativeItem(count).Height(8).Background(Colors.Blue.Medium);
                            if (max - count > 0) row.RelativeItem(max - count);
                        });
                    }
                }
            });
        }

        public static IContainer HeaderCell(IContainer container) =>
            container.Background(Colors.Grey.Lighten3).Padding(4);

        public static IContainer BodyCell(IContainer container) =>
            container.BorderBottom(1).BorderColor(Colors.Grey.Lighten3).Padding(4);

        public static string FormatDate(DateTime? date) => date?.ToString("yyyy-MM-dd") ?? "-";

        public static string FormatDuration(TimeSpan duration) =>
            duration.TotalHours < 24
                ? $"{Math.Max(1, (int)Math.Round(duration.TotalHours))} h"
                : $"{(int)duration.TotalDays} d {duration.Hours} h";

        public static string StatusLabel(string? status) => status switch
        {
            nameof(UnseenReportState) => "Unseen",
            nameof(SeenReportState) => "Seen",
            nameof(ClearedReportState) => "Cleared",
            nameof(DraftReportState) => "Draft",
            _ => status ?? "-",
        };
    }
}
