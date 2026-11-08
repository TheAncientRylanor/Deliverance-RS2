using Deliverance.Model.Enums;
using Deliverance.Model.Exceptions;
using Deliverance.Model.Responses;
using Deliverance.Services;
using Deliverance.Services.Database;
using Microsoft.EntityFrameworkCore;
using Microsoft.ML;
using Microsoft.ML.Data;

public class DeviceRecommendationService : IDeviceRecommendationService
{
    private const int HorizonDays = 14;
    // The log lines the model reads for a device, and the admin sees as evidence.
    private const int RecentLogDays = 7;
    private const int RecentLogsLimit = 20;
    private const int EvidenceReportDays = 90;
    private const int EvidenceReportsLimit = 10;
    // A fix gets as long to prove itself as the period the model predicts.
    private const int RecentlyFixedDays = HorizonDays;
    private static readonly string ModelPath =
        Path.Combine(AppContext.BaseDirectory, "MLModels", "device-issue-model.zip");

    // Shared across requests so the model is loaded once, not on every call.
    private static readonly MLContext _ml = new(seed: 1);
    private static ITransformer? _model;

    private readonly DeliveranceDbContext _dbContext;

    public DeviceRecommendationService(DeliveranceDbContext dbContext)
    {
        _dbContext = dbContext;
    }
    // Loads every device's history, or only one device's when deviceId is set.
    public async Task<(List<ReportPoint>, List<LogPoint>)> LoadHistoryAsync(int? deviceId = null)
    {
        var reportQuery = _dbContext.DeviceReports
            .Where(dr => dr.OfficeReport!.Report!.Status != nameof(DraftReportState));
        var logQuery = _dbContext.DeviceLogs.AsQueryable();

        if (deviceId.HasValue)
        {
            reportQuery = reportQuery.Where(dr => dr.DeviceId == deviceId.Value);
            logQuery = logQuery.Where(l => l.Scout!.DeviceId == deviceId.Value);
        }

        var reports = await reportQuery
            .Select(dr => new ReportPoint(
                dr.DeviceId,
                dr.OfficeReport!.Report!.DateReported,
                dr.OfficeReport.Report.Severity,
                dr.OfficeReport.Report.IssueType,
                dr.OfficeReport.Report.Status == nameof(ClearedReportState),
                dr.OfficeReport.Report.DateCleared))
            .ToListAsync();

        var logs = await logQuery
            .Select(l => new LogPoint(l.Scout!.DeviceId, l.DateLogged, l.Log))
            .ToListAsync();

        return (reports, logs);
    }
    private static List<LogPoint> GetRecentLogs(int deviceId, DateTime asOf, List<LogPoint> logs) =>
        logs
            .Where(l => l.DeviceId == deviceId && l.Date < asOf && l.Date >= asOf.AddDays(-RecentLogDays))
            .OrderByDescending(l => l.Date)
            .ToList();

    private static DeviceIssueInput BuildFeatures(int deviceId, DateTime asOf,
        List<ReportPoint> reports, List<LogPoint> logs)
    {
        var before = reports.Where(r => r.DeviceId == deviceId && r.Date < asOf).ToList();
        var last90 = before.Where(r => r.Date >= asOf.AddDays(-90)).ToList();
        var recentLogs = GetRecentLogs(deviceId, asOf, logs);

        return new DeviceIssueInput
        {
            ReportsLast7Days = before.Count(r => r.Date >= asOf.AddDays(-7)),
            ReportsLast30Days = before.Count(r => r.Date >= asOf.AddDays(-30)),
            ReportsLast90Days = last90.Count,
            AvgSeverity = last90.Count == 0 ? 0 : (float)last90.Average(r => (int)(r.Severity ?? SeverityEnum.None)),
            MaxSeverity = last90.Count == 0 ? 0 : last90.Max(r => (int)(r.Severity ?? SeverityEnum.None)),
            PastHardwareIssues = before.Count(r => r.IssueType is IssueEnum.Hardware or IssueEnum.Both),
            PastSoftwareIssues = before.Count(r => r.IssueType is IssueEnum.Software or IssueEnum.Both),
            DaysSinceLastReport = before.Count == 0 ? 365 : (float)Math.Min(365, (asOf - before.Max(r => r.Date)).TotalDays),
            LogsLast7Days = recentLogs.Count,
            RecentLogs = string.Join(" ", recentLogs.Take(RecentLogsLimit).Select(l => l.Text)),
        };
    }
    private static List<DeviceIssueInput> BuildTrainingRows(List<Device> devices,
    List<ReportPoint> reports, List<LogPoint> logs)
    {
        var rows = new List<DeviceIssueInput>();
        if (reports.Count == 0) return rows;

        var start = reports.Min(r => r.Date).Date;
        var end = DateTime.UtcNow.AddDays(-HorizonDays);

        for (var t = start.AddDays(7); t <= end; t = t.AddDays(7))
        {
            foreach (var device in devices)
            {
                var upcoming = reports
                    .Where(r => r.DeviceId == device.Id && r.Date >= t && r.Date < t.AddDays(HorizonDays))
                    .ToList();

                string label;
                if (upcoming.Count == 0)
                {
                    label = "None";
                }
                else
                {
                    var labelled = upcoming.Where(r => r.IssueType != null).OrderBy(r => r.Date).FirstOrDefault();
                    if (labelled == null) continue; // reported, but nobody said what kind
                    label = labelled.IssueType!.Value.ToString();
                }

                var row = BuildFeatures(device.Id, t, reports, logs);
                row.Label = label;
                rows.Add(row);
            }
        }
        return rows;
    }
    private static IEstimator<ITransformer> BuildPipeline() =>
    // 1. Turn the text label ("Hardware") into an internal number
    _ml.Transforms.Conversion.MapValueToKey("Label")
        // 2. Turn log text into numbers (word/character counts)
        .Append(_ml.Transforms.Text.FeaturizeText("LogFeatures", nameof(DeviceIssueInput.RecentLogs)))
        // 3. Put the numeric features into one vector...
        .Append(_ml.Transforms.Concatenate("NumFeatures",
            nameof(DeviceIssueInput.ReportsLast7Days), nameof(DeviceIssueInput.ReportsLast30Days),
            nameof(DeviceIssueInput.ReportsLast90Days), nameof(DeviceIssueInput.AvgSeverity),
            nameof(DeviceIssueInput.MaxSeverity), nameof(DeviceIssueInput.PastHardwareIssues),
            nameof(DeviceIssueInput.PastSoftwareIssues), nameof(DeviceIssueInput.DaysSinceLastReport),
            nameof(DeviceIssueInput.LogsLast7Days)))
        // ...and scale them to 0..1 so "365 days" doesn't drown out "severity 4"
        .Append(_ml.Transforms.NormalizeMinMax("NumFeatures"))
        // 4. Everything the algorithm looks at goes into "Features"
        .Append(_ml.Transforms.Concatenate("Features", "NumFeatures", "LogFeatures"))
        // 5. The algorithm
        .Append(_ml.MulticlassClassification.Trainers.SdcaMaximumEntropy())
        // 6. Turn the predicted number back into "Hardware"/"Software"/...
        .Append(_ml.Transforms.Conversion.MapKeyToValue("PredictedLabel"));

    public async Task<RecommendationTrainingResponse> TrainAsync(bool isAdmin)
    {
        EnsureAdmin(isAdmin);
        return await TrainModelAsync();
    }

    private async Task<RecommendationTrainingResponse> TrainModelAsync()
    {
        var devices = await _dbContext.Devices.AsNoTracking().ToListAsync();
        var (reports, logs) = await LoadHistoryAsync();
        var rows = BuildTrainingRows(devices, reports, logs);

        // Without "None" rows the model has never seen a healthy device, so it would score every device 100%.
        var labels = rows.Select(r => r.Label).Distinct().ToList();
        if (labels.Count < 2 || !labels.Contains("None"))
        {
            throw new BusinessException("Not enough report history to train the recommendation model.");
        }

        var data = _ml.Data.LoadFromEnumerable(rows);
        var pipeline = BuildPipeline();

        // Rows are oldest-first, so test on the newest 20%. A random split would put
        // neighbouring, near-identical weeks of a device on both sides.
        var cut = (int)(rows.Count * 0.8);
        var trainSet = _ml.Data.LoadFromEnumerable(rows.Take(cut));
        var testSet = _ml.Data.LoadFromEnumerable(rows.Skip(cut));
        var metrics = _ml.MulticlassClassification.Evaluate(
            pipeline.Fit(trainSet).Transform(testSet));

        // Then train the real model on all data and save it.
        var model = pipeline.Fit(data);
        Directory.CreateDirectory(Path.GetDirectoryName(ModelPath)!);
        _ml.Model.Save(model, data.Schema, ModelPath);
        _model = model;

        return new RecommendationTrainingResponse
        {
            Rows = rows.Count,
            MicroAccuracy = metrics.MicroAccuracy,
            MacroAccuracy = metrics.MacroAccuracy,
            LogLoss = metrics.LogLoss,
        };
    }

    private async Task<ITransformer> GetModelAsync()
    {
        if (_model != null) return _model;
        if (File.Exists(ModelPath))
        {
            _model = _ml.Model.Load(ModelPath, out _);
            return _model;
        }
        await TrainModelAsync(); // first request ever: train on the spot
        return _model!;
    }
    public async Task<List<DeviceRecommendationResponse>> GetRecommendationsAsync(int top, int minReports,
        float minProbability, bool isAdmin)
    {
        EnsureAdmin(isAdmin);
        top = Math.Clamp(top, 1, 100);
        var model = await GetModelAsync();
        var devices = await _dbContext.Devices.AsNoTracking().ToListAsync();
        var (reports, logs) = await LoadHistoryAsync();
        var now = DateTime.UtcNow;

        return ScoreDevices(model, devices, now, reports, logs)
            .Where(r => r.ReportsLast30Days >= minReports && r.NeedsFixProbability >= minProbability)
            .Where(r => !IsRecentlyFixed(r.DeviceId, now, reports, logs))
            .OrderByDescending(r => r.NeedsFixProbability)
            .Take(top)
            .ToList();
    }

    // Every device's score, without the limit and filters of GetRecommendationsAsync.
    public async Task<List<DeviceRecommendationResponse>> ScoreAllDevicesAsync(bool isAdmin)
    {
        EnsureAdmin(isAdmin);
        var model = await GetModelAsync();
        var devices = await _dbContext.Devices.AsNoTracking().ToListAsync();
        var (reports, logs) = await LoadHistoryAsync();
        return ScoreDevices(model, devices, DateTime.UtcNow, reports, logs);
    }

    public async Task<DeviceEvidenceResponse> GetDeviceEvidenceAsync(int deviceId, bool isAdmin)
    {
        EnsureAdmin(isAdmin);
        var device = await _dbContext.Devices.AsNoTracking().FirstOrDefaultAsync(d => d.Id == deviceId)
            ?? throw new NotFoundException($"Device with id {deviceId} not found.");

        var model = await GetModelAsync();
        var (reports, logs) = await LoadHistoryAsync(deviceId);
        var now = DateTime.UtcNow;
        var reportsFrom = now.AddDays(-EvidenceReportDays);

        return new DeviceEvidenceResponse
        {
            Recommendation = ScoreDevices(model, [device], now, reports, logs).Single(),
            Logs = GetRecentLogs(deviceId, now, logs)
                .Take(RecentLogsLimit)
                .Select(l => new DeviceEvidenceLogResponse { DateLogged = l.Date, Log = l.Text ?? string.Empty })
                .ToList(),
            Reports = await _dbContext.DeviceReports
                .AsNoTracking()
                .Where(dr => dr.DeviceId == deviceId
                    && dr.OfficeReport!.Report!.Status != nameof(DraftReportState)
                    && dr.OfficeReport.Report.DateReported >= reportsFrom)
                .OrderByDescending(dr => dr.OfficeReport!.Report!.DateReported)
                .Take(EvidenceReportsLimit)
                .Select(dr => new DeviceEvidenceReportResponse
                {
                    ReportId = dr.OfficeReport!.ReportId,
                    ReportName = dr.OfficeReport.Report!.ReportName,
                    DateReported = dr.OfficeReport.Report.DateReported,
                    Status = dr.OfficeReport.Report.Status,
                    Severity = dr.OfficeReport.Report.Severity,
                    IssueType = dr.OfficeReport.Report.IssueType,
                    // What was reported about this device, or else about the report as a whole.
                    Detail = dr.Detail ?? dr.OfficeReport.Report.Detail,
                    Comment = dr.OfficeReport.Report.Comment,
                })
                .ToListAsync(),
        };
    }

    // The score still counts the reports from before the fix, so a repaired device would
    // stay on top. It is left out until something shows the fix didn't work: an open
    // report or a new log line. Scouts only send faults, so any new line counts.
    private static bool IsRecentlyFixed(int deviceId, DateTime now, List<ReportPoint> reports, List<LogPoint> logs)
    {
        var deviceReports = reports.Where(r => r.DeviceId == deviceId).ToList();
        if (deviceReports.Any(r => !r.IsCleared)) return false;

        var lastFix = deviceReports.Max(r => r.DateCleared);
        if (lastFix == null || lastFix < now.AddDays(-RecentlyFixedDays)) return false;

        return !logs.Any(l => l.DeviceId == deviceId && l.Date > lastFix);
    }

    private static List<DeviceRecommendationResponse> ScoreDevices(ITransformer model, List<Device> devices,
        DateTime now, List<ReportPoint> reports, List<LogPoint> logs)
    {
        // Every device "as of now", predicted in one batch.
        var inputs = devices.Select(d => BuildFeatures(d.Id, now, reports, logs)).ToList();
        var output = model.Transform(_ml.Data.LoadFromEnumerable(inputs));
        var predictions = _ml.Data.CreateEnumerable<DeviceIssuePrediction>(output, reuseRowObject: false).ToList();

        // Score[i] belongs to labels[i]; the order is decided by ML.NET, so ask it.
        VBuffer<ReadOnlyMemory<char>> slotNames = default;
        output.Schema["Score"].GetSlotNames(ref slotNames);
        var labels = slotNames.DenseValues().Select(x => x.ToString()).ToList();
        var noneIndex = labels.IndexOf("None");

        return devices
            .Select((device, i) =>
            {
                var scores = predictions[i].Score;
                var likely = labels
                    .Select((label, idx) => (label, score: scores[idx]))
                    .Where(x => x.label != "None")
                    .OrderByDescending(x => x.score)
                    .First();

                return new DeviceRecommendationResponse
                {
                    DeviceId = device.Id,
                    DeviceName = device.Name,
                    OfficeName = device.OfficeName,
                    NeedsFixProbability = 1f - scores[noneIndex],
                    LikelyIssue = Enum.Parse<IssueEnum>(likely.label),
                    ReportsLast30Days = (int)inputs[i].ReportsLast30Days,
                };
            })
            .ToList();
    }

    // Recommendations cover every office, so they are for admins only.
    private static void EnsureAdmin(bool isAdmin)
    {
        if (!isAdmin)
        {
            throw new ForbiddenException("You do not have access to this resource.");
        }
    }
}