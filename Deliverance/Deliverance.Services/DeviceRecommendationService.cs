using Deliverance.Services.ReportStateMachine;
using Deliverance.Model.Enums;
using Deliverance.Model.Exceptions;
using Deliverance.Model.Responses;
using Deliverance.Services.Database;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.ML;
using Microsoft.ML.Data;
using System.Text.Json;

namespace Deliverance.Services;

public class DeviceRecommendationService : IDeviceRecommendationService
{
    private const int HorizonDays = 14;
    private const int RecentLogDays = 7;
    public const int RecentLogsLimit = 20;
    private const int EvidenceReportDays = 90;
    private const int EvidenceReportsLimit = 10;
    private const int RecentlyFixedDays = HorizonDays;
    private static readonly string ModelPath =
        Path.Combine(AppContext.BaseDirectory, "MLModels", "device-issue-model.zip");
    private static readonly string TrainingInfoPath = Path.ChangeExtension(ModelPath, ".json");

    private const string ModelCacheKey = "recommendation:device-issue-model";
    private static readonly SemaphoreSlim ModelLock = new(1, 1);
    private static readonly MLContext _ml = new(seed: 1);

    private readonly DeliveranceDbContext _dbContext;
    private readonly IMemoryCache _cache;

    public DeviceRecommendationService(DeliveranceDbContext dbContext, IMemoryCache cache)
    {
        _dbContext = dbContext;
        _cache = cache;
    }
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
                    if (labelled == null) continue;
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
    _ml.Transforms.Conversion.MapValueToKey("Label")
        .Append(_ml.Transforms.Text.FeaturizeText("LogFeatures", nameof(DeviceIssueInput.RecentLogs)))
        .Append(_ml.Transforms.Concatenate("NumFeatures",
            nameof(DeviceIssueInput.ReportsLast7Days), nameof(DeviceIssueInput.ReportsLast30Days),
            nameof(DeviceIssueInput.ReportsLast90Days), nameof(DeviceIssueInput.AvgSeverity),
            nameof(DeviceIssueInput.MaxSeverity), nameof(DeviceIssueInput.PastHardwareIssues),
            nameof(DeviceIssueInput.PastSoftwareIssues), nameof(DeviceIssueInput.DaysSinceLastReport),
            nameof(DeviceIssueInput.LogsLast7Days)))
        .Append(_ml.Transforms.NormalizeMinMax("NumFeatures"))
        .Append(_ml.Transforms.Concatenate("Features", "NumFeatures", "LogFeatures"))
        .Append(_ml.MulticlassClassification.Trainers.SdcaMaximumEntropy())
        .Append(_ml.Transforms.Conversion.MapKeyToValue("PredictedLabel"));

    public async Task<RecommendationTrainingResponse> TrainAsync(bool isAdmin)
    {
        EnsureAdmin(isAdmin);
        await ModelLock.WaitAsync();
        try
        {
            return await TrainModelAsync();
        }
        finally
        {
            ModelLock.Release();
        }
    }

    private async Task<RecommendationTrainingResponse> TrainModelAsync()
    {
        var devices = await _dbContext.Devices.AsNoTracking().ToListAsync();
        var (reports, logs) = await LoadHistoryAsync();
        var rows = BuildTrainingRows(devices, reports, logs);

        var labels = rows.Select(r => r.Label).Distinct().ToList();
        if (labels.Count < 2 || !labels.Contains("None"))
        {
            throw new BusinessException("Not enough report history to train the recommendation model.");
        }

        var data = _ml.Data.LoadFromEnumerable(rows);
        var pipeline = BuildPipeline();

        var cut = (int)(rows.Count * 0.8);
        var trainSet = _ml.Data.LoadFromEnumerable(rows.Take(cut));
        var testSet = _ml.Data.LoadFromEnumerable(rows.Skip(cut));
        var metrics = _ml.MulticlassClassification.Evaluate(
            pipeline.Fit(trainSet).Transform(testSet));

        var model = pipeline.Fit(data);
        Directory.CreateDirectory(Path.GetDirectoryName(ModelPath)!);
        _ml.Model.Save(model, data.Schema, ModelPath);
        CacheModel(model);

        var trainingInfo = new RecommendationTrainingResponse
        {
            TrainedAt = DateTime.UtcNow,
            Rows = rows.Count,
            MicroAccuracy = metrics.MicroAccuracy,
            MacroAccuracy = metrics.MacroAccuracy,
            LogLoss = metrics.LogLoss,
        };
        await File.WriteAllTextAsync(TrainingInfoPath, JsonSerializer.Serialize(trainingInfo));
        return trainingInfo;
    }

    public async Task<RecommendationTrainingResponse> GetTrainingInfoAsync(bool isAdmin)
    {
        EnsureAdmin(isAdmin);
        if (File.Exists(TrainingInfoPath))
        {
            var saved = JsonSerializer.Deserialize<RecommendationTrainingResponse>(
                await File.ReadAllTextAsync(TrainingInfoPath));
            if (saved?.TrainedAt != null)
            {
                saved.TrainedAt = saved.TrainedAt.Value.AsUtc();
                return saved;
            }
        }
        return new RecommendationTrainingResponse
        {
            TrainedAt = File.Exists(ModelPath) ? File.GetLastWriteTimeUtc(ModelPath) : null,
        };
    }

    private async Task<ITransformer> GetModelAsync()
    {
        if (_cache.TryGetValue(ModelCacheKey, out ITransformer? cached))
        {
            return cached!;
        }

        await ModelLock.WaitAsync();
        try
        {
            if (_cache.TryGetValue(ModelCacheKey, out cached))
            {
                return cached!;
            }
            if (File.Exists(ModelPath))
            {
                return CacheModel(_ml.Model.Load(ModelPath, out _));
            }
            await TrainModelAsync();
            return _cache.Get<ITransformer>(ModelCacheKey)!;
        }
        finally
        {
            ModelLock.Release();
        }
    }

    private ITransformer CacheModel(ITransformer model)
        => _cache.Set(ModelCacheKey, model, new MemoryCacheEntryOptions { Priority = CacheItemPriority.NeverRemove });
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
            ?? throw new NotFoundException($"Device with id {deviceId} was not found.");

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
                    Detail = dr.Detail ?? dr.OfficeReport.Report.Detail,
                    Comment = dr.OfficeReport.Report.Comment,
                })
                .ToListAsync(),
        };
    }

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
        var inputs = devices.Select(d => BuildFeatures(d.Id, now, reports, logs)).ToList();
        var output = model.Transform(_ml.Data.LoadFromEnumerable(inputs));
        var predictions = _ml.Data.CreateEnumerable<DeviceIssuePrediction>(output, reuseRowObject: false).ToList();

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

    private static void EnsureAdmin(bool isAdmin)
    {
        if (!isAdmin)
        {
            throw new ForbiddenException("You do not have access to this resource.");
        }
    }
}