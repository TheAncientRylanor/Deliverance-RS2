# Device-fix recommender

Deliverance has a built-in machine-learning recommender. It tells administrators **which devices are likely to need a fix soon**, and **what kind of fix** (hardware, software or both), before users report the problem.

This document covers what the recommender is for, the data it learns from, the algorithm, how training and scoring work, and where the results appear in the apps.

---

## Contents

1. [Purpose](#1-purpose)
2. [The idea in one paragraph](#2-the-idea-in-one-paragraph)
3. [Data sources](#3-data-sources)
4. [Turning history into training examples](#4-turning-history-into-training-examples)
5. [Features](#5-features)
6. [The algorithm: SDCA Maximum Entropy](#6-the-algorithm-sdca-maximum-entropy)
7. [The ML.NET pipeline](#7-the-mlnet-pipeline)
8. [Training](#8-training)
9. [Scoring and ranking](#9-scoring-and-ranking)
10. [The "recently fixed" filter](#10-the-recently-fixed-filter)
11. [API](#11-api)
12. [Where the results are used](#12-where-the-results-are-used)
13. [Code map](#13-code-map)

---

## 1. Purpose

Admins in an organisation look after many devices spread across many offices. Without help they only find out about a problem when someone files a report, and by then the device is already failing.

The recommender changes the question from _"what is broken?"_ to _"what is about to break?"_. It:

- **ranks devices by risk**: the probability that a fault will be reported for the device in the next **14 days**;
- **predicts the likely issue type**: `Hardware`, `Software` or `Both`, so the admin knows whether to bring tools or a laptop with an installer;
- **shows the evidence** behind each prediction (recent system logs and reports), so the admin makes the final decision instead of trusting a black box.

It is a decision-support tool. It never changes data, opens reports or contacts users by itself.

## 2. The idea in one paragraph

Every week of the past is replayed. For each device we ask: _"Looking only at what was known at that moment, would a problem be reported in the next 14 days, and of which type?"_ The answer is known for the past, so those weeks become labelled training examples. A multiclass classifier (ML.NET's **SDCA Maximum Entropy**, a multinomial logistic regression) learns from them. To score a device today we build the same features for _now_ and ask the model for the probability of each outcome. The risk is `1 − P(no problem)`.

## 3. Data sources

The recommender reads two kinds of history from the database.

### Reports

Users report problems from the mobile app. A report covers one or more offices and, within each office, one or more devices (`Report` → `OfficeReport` → `DeviceReport`). From each device row the recommender uses:

| Field                                                                | Used for                                       |
| -------------------------------------------------------------------- | ---------------------------------------------- |
| `DateReported`                                                       | when the problem was reported                  |
| `Severity` (`None`=1, `Mild`=2, `Medium`=3, `Danger`=4, `Extreme`=5) | severity features                              |
| `IssueType` (`Hardware`, `Software`, `Both`)                         | past-issue features and the **training label** |
| `Status`, `DateCleared`                                              | the "recently fixed" filter                    |

**Draft reports are ignored**, because they haven't been sent and may never be.

The `IssueType` is set by the reporting user and **corrected by the admin when the report is cleared** (`ReportClearRequest { Comment, IssueType }`). Labels therefore get more accurate as admins close reports.

### Device logs

The **Deliverance Scout** agent runs on each managed Windows device. Every 15 minutes it collects notable events (from the Windows System event log, plus checks such as long periods of high memory use) and sends them to `POST Scout/Logs`. They are stored as `DeviceLog` rows with a date and a free-text line.

Logs often show trouble before anyone reports it (disk warnings, driver crashes, unexpected shutdowns), which is why the recommender uses them.

## 4. Turning history into training examples

A classifier needs examples of the form _features → correct answer_. The recommender builds them with **weekly snapshots**.

```
             past (features)                    future (label)
  ◄──────────────────────────────────── T ─────────────────────►
   90 days of reports │ 7 days of logs  │   next 14 days
                                        │   first report here → its IssueType
                                        │   no report         → "None"
```

1. **Features** are computed from data strictly **before `T`** (see [Features](#5-features)).
2. **Label** is decided by looking at the window `[T, T + 14 days)`:
   - no report for the device → `None`;
   - otherwise → the `IssueType` of the **first** report in that window that has one;
   - reports exist but none has an issue type → the snapshot is **skipped** (the outcome is unknown, so it would be a wrong `None`).

The last snapshot is 14 days before today because a later one wouldn't have a complete 14-day future yet, and its label could be wrong.

Since features only use data before `T` and the label only data after `T`, the model never sees the answer while learning (no _data leakage_). Training and live scoring use **the same function** (`BuildFeatures(deviceId, asOf, …)`), so a feature means exactly the same thing in both.

### Example

| Device    | Snapshot `T` | Reports last 30 d | Logs last 7 d | What happened in the next 14 d | Label      |
| --------- | ------------ | ----------------- | ------------- | ------------------------------ | ---------- |
| PC-12     | 2026-09-07   | 0                 | 2             | nothing                        | `None`     |
| PC-12     | 2026-09-14   | 0                 | 31            | Hardware report on 09-19       | `Hardware` |
| PC-12     | 2026-09-21   | 1                 | 6             | nothing                        | `None`     |
| Printer-3 | 2026-09-14   | 2                 | 0             | Software report on 09-15       | `Software` |

Most rows are `None`, because most devices are fine most weeks. That matches reality, and it is why the model's raw accuracy needs careful reading (see [Training](#8-training)).

## 5. Features

Each snapshot is described by nine numbers and one block of text.

| Feature               | Meaning                                                           | Why it helps                                          |
| --------------------- | ----------------------------------------------------------------- | ----------------------------------------------------- |
| `ReportsLast7Days`    | reports in the last 7 days                                        | very recent trouble                                   |
| `ReportsLast30Days`   | reports in the last 30 days                                       | medium-term trend                                     |
| `ReportsLast90Days`   | reports in the last 90 days                                       | long-term "problem device"                            |
| `AvgSeverity`         | average severity (1–5) of reports in the last 90 days, 0 if none  | how bad its problems usually are                      |
| `MaxSeverity`         | highest severity in the last 90 days, 0 if none                   | one serious incident matters                          |
| `PastHardwareIssues`  | all-time count of `Hardware` or `Both` reports                    | ageing hardware tends to fail again                   |
| `PastSoftwareIssues`  | all-time count of `Software` or `Both` reports                    | recurring software problems                           |
| `DaysSinceLastReport` | days since the last report, capped at 365 (365 if never reported) | recency                                               |
| `LogsLast7Days`       | number of scout log lines in the last 7 days                      | a device that suddenly logs a lot is often in trouble |
| `RecentLogs` (text)   | the newest 20 log lines from the last 7 days, joined              | _what_ the device is complaining about                |

The numbers capture **how much** and **how bad**. The log text captures **what kind** of trouble, which is what separates a hardware prediction (disk, temperature, power words) from a software one (application crash, update, service failure words).

## 6. The algorithm: SDCA Maximum Entropy

### What it is

**Maximum Entropy** classification is another name for **multinomial (softmax) logistic regression**. For each class _c_ (`None`, `Hardware`, `Software`, `Both`) the model learns a weight vector **w**<sub>c</sub> and a bias _b_<sub>c</sub>. For a feature vector **x** it computes one score per class and turns the scores into probabilities with softmax:

```
score_c(x) = w_c · x + b_c

P(c | x)   = exp(score_c(x)) / Σ_k exp(score_k(x))
```

The four probabilities are each between 0 and 1 and add up to 1.

Training finds the weights that **maximise the likelihood** of the correct labels in the training data, which is the same as minimising the cross-entropy (log loss), plus **L2 regularisation** that keeps the weights small so the model doesn't memorise noise.

### SDCA: how the weights are found

**SDCA** (Stochastic Dual Coordinate Ascent) is the optimiser. Instead of gradient descent on the weights, it works on the _dual_ form of the regularised problem and updates one training example's dual variable at a time. In practice:

- it converges in a few passes over the data, with no learning rate to tune;
- it handles large, **sparse** feature vectors well, and the text features are sparse (thousands of possible words, few present per row);
- with a fixed seed (`new MLContext(seed: 1)`) training is reproducible.

### Why this algorithm

| Need                                                         | How SDCA Maximum Entropy meets it                                              |
| ------------------------------------------------------------ | ------------------------------------------------------------------------------ |
| A **probability**, not just a label, to rank devices by risk | softmax output gives P(class) directly                                         |
| Several outcomes (none / hardware / software / both)         | natively multiclass                                                            |
| Mixed numeric and text features                              | linear model over a concatenated, normalised vector                            |
| Small or medium datasets                                     | linear models with regularisation generalise well with little data             |
| Runs inside the API, no GPU, no external service             | ML.NET, pure .NET, trains in seconds                                           |
| Explainable                                                  | each class is a weighted sum of features; the evidence screen shows the inputs |

Tree ensembles (e.g. LightGBM) or neural networks could fit more complex patterns, but they need more data, more tuning and give less directly interpretable probabilities. For a system where admins act on the ranking, a well-understood linear probabilistic model is the safer choice.

## 7. The ML.NET pipeline

```csharp
MapValueToKey("Label")                            // "None"/"Hardware"/... → class index
  → FeaturizeText("LogFeatures", RecentLogs)      // log text → sparse numeric vector
  → Concatenate("NumFeatures", <9 numeric features>)
  → NormalizeMinMax("NumFeatures")                // scale each number to [0, 1]
  → Concatenate("Features", NumFeatures, LogFeatures)
  → SdcaMaximumEntropy()                          // the classifier
  → MapKeyToValue("PredictedLabel")               // class index → "Hardware" etc.
```

Step by step:

1. **`MapValueToKey`**: the trainer needs class indices, not strings.
2. **`FeaturizeText`**: lower-cases and tokenises the log text, counts word n-grams and character n-grams, and normalises the result. Similar lines such as `disk 0 has a bad block` and `disk 1 has a bad block` end up close together.
3. **`NormalizeMinMax`**: the numeric features have very different ranges (a severity of 1–5 next to 365 days). Scaling them to `[0, 1]` stops large-valued features from dominating the weights.
4. **`Concatenate`**: joins numbers and text into one `Features` vector.
5. **`SdcaMaximumEntropy`**: learns the weights and outputs a `Score` vector holding one probability per class.
6. **`MapKeyToValue`**: turns the winning index back into a readable label.

## 8. Training

Training is triggered by an admin with `POST Recommendation/Train`, or automatically the first time a recommendation is requested and no saved model exists.

1. Load all devices, all non-draft device reports and all device logs.
2. Build the weekly snapshot rows ([section 4](#4-turning-history-into-training-examples)).
3. **Sanity check**: at least two different labels, one of them `None`. Otherwise the API returns a `400` with _"Not enough report history to train the recommendation model."_
4. **Evaluate**: rows are in time order (oldest snapshot first), so the first 80 % train a temporary model and the **newest 20 % test it**. This is a time-based split: the model is tested on weeks it has never seen and that come after everything it learned from, which is how it will be used.
5. **Final fit**: the pipeline is fitted again on **all** rows, so the saved model also learns from the most recent weeks.
6. **Save and cache**: the model is written to `MLModels/device-issue-model.zip` next to the API binaries and kept in `IMemoryCache` (never evicted). After a restart it is loaded from disk instead of retrained.

A `SemaphoreSlim` makes sure only one training or load runs at a time.

### Training response

```json
{
  "rows": 4160,
  "microAccuracy": 0.91,
  "macroAccuracy": 0.58,
  "logLoss": 0.31
}
```

| Metric          | Meaning                                                                | How to read it                                                                       |
| --------------- | ---------------------------------------------------------------------- | ------------------------------------------------------------------------------------ |
| `rows`          | number of snapshot rows built                                          | more history means more rows                                                         |
| `microAccuracy` | share of all test rows predicted correctly                             | **looks good even for a weak model**, because most rows are `None`                   |
| `macroAccuracy` | accuracy computed per class, then averaged                             | treats the rare classes as equally important, so it's the more honest number         |
| `logLoss`       | average cross-entropy of the predicted probabilities (lower is better) | measures whether the **probabilities** are good, which is what the ranking relies on |

_(The numbers above are illustrative.)_

## 9. Scoring and ranking

When recommendations are requested:

1. Load the model (cache → disk → train).
2. Build features for **every device as of now** with the same `BuildFeatures` used in training.
3. Run the whole batch through `model.Transform` in one call (no per-device prediction engine).
4. For each device read the four class probabilities and derive:

```
NeedsFixProbability = 1 − P(None)
LikelyIssue         = the class with the highest probability among Hardware, Software, Both
```

### Example

|              | None | Hardware | Software | Both |
| ------------ | ---- | -------- | -------- | ---- |
| model output | 0.22 | 0.51     | 0.17     | 0.10 |

→ **NeedsFixProbability = 78 %**, **LikelyIssue = Hardware**.

`LikelyIssue` is chosen among the three problem classes even when `None` is the largest probability, so the admin always sees what kind of problem would be most likely.

5. Filter and sort:
   - keep devices with at least `minReports` reports in the last 30 days (default 0);
   - keep devices with `NeedsFixProbability ≥ minProbability` (default 0);
   - drop devices that were **recently fixed** (next section);
   - sort by `NeedsFixProbability`, highest first, and take `top` (default 10, max 100).

## 10. The "recently fixed" filter

Straight after an admin fixes a device, its history still looks bad (many recent reports, high severity), so the model would keep ranking it as risky, and the list would fill with devices that were just repaired.

So the ranking **hides a device for 14 days after its last fix**, unless something new happens. A device is hidden only if **all** of these are true:

- all of its reports are cleared (none is still open);
- its most recent `DateCleared` is within the last 14 days;
- the scout has sent **no new log line** since that fix.

An open report or a new log line brings the device back immediately. This is a rule applied to the ranking, not a model feature: the model's probabilities are unchanged, and the device-health PDF still shows the device's score.

## 11. API

All endpoints require a signed-in **administrator**. Other users get `403`.

| Method | Route                                                  | Description                                                 |
| ------ | ------------------------------------------------------ | ----------------------------------------------------------- |
| `GET`  | `/Recommendation?top=10&minReports=0&minProbability=0` | ranked list of devices likely to need a fix                 |
| `GET`  | `/Recommendation/{deviceId}/Evidence`                  | one device's score plus the data behind it                  |
| `POST` | `/Recommendation/Train`                                | retrain the model on the current history and return metrics |

### `GET /Recommendation`

```json
[
  {
    "deviceId": 42,
    "deviceName": "PC-12",
    "officeName": "Accounting",
    "needsFixProbability": 0.78,
    "likelyIssue": 1,
    "reportsLast30Days": 3
  }
]
```

`likelyIssue` is the `IssueEnum` value: `1` = Hardware, `2` = Software, `3` = Both.

### `GET /Recommendation/{deviceId}/Evidence`

Returns the device's `recommendation` (same shape as above, scored even if it would be filtered out of the list), plus:

- `logs`: the newest 20 scout log lines from the last 7 days, the same lines the model read;
- `reports`: up to 10 non-draft reports from the last 90 days, with status, severity, issue type, details and the admin's comment.

## 12. Where the results are used

### Desktop app: Statistics screen

The **Critical devices** section shows the **top 5 devices with at least 50 % risk** as cards (device, office, fix probability, likely issue, with an icon for hardware, software or both). The list is loaded once when the screen opens, so changing the statistics filters doesn't rescore.

### Desktop app: Critical device screen

Clicking a card opens the evidence: the recent logs and reports behind the prediction. Each report opens the full report screen, and the evidence reloads on return, so after clearing a report the admin sees the updated state.

### Chat assistant

When an admin asks the assistant about a specific device, the chat service builds the prompt from the same evidence: the risk percentage, the likely issue type, the most frequent log lines of the last 7 days and the reports of the last 90 days. The assistant (a local Llama model via Ollama) then helps interpret the evidence. The recommender decides _which_ device needs attention, and the assistant helps with _what to do about it_.

### Device health PDF report

The device-health PDF scores every device and lists its risk and likely issue next to its report counts and last fix date. It counts how many devices are at 50 % or higher, and includes recent logs for the top 5 risky devices.

## 13. Code map

| What                                                                    | Where                                                                                                                                           |
| ----------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- |
| Recommender service (features, training, scoring, evidence)             | `Deliverance.Services/DeviceRecommendationService.cs`                                                                                           |
| Service interface, `ReportPoint` / `LogPoint` records                   | `Deliverance.Services/IDeviceRecommendationService.cs`                                                                                          |
| ML input / output classes (`DeviceIssueInput`, `DeviceIssuePrediction`) | `Deliverance.Services`                                                                                                                          |
| API endpoints                                                           | `Deliverance.WebAPI/Controllers/RecommendationController.cs`                                                                                    |
| Response DTOs                                                           | `Deliverance.Model/Responses/DeviceRecommendationResponse.cs`, `DeviceEvidenceResponse.cs`, `RecommendationTrainingResponse.cs`                 |
| Chat assistant device prompt                                            | `Deliverance.Services/ChatBotService.cs`                                                                                                        |
| Device-health PDF                                                       | `Deliverance.Services/PdfReportService.cs`, `Deliverance.Services/Pdf/DeviceHealthDocument.cs`                                                  |
| Desktop: critical device cards and evidence                             | `UI/deliverance_desktop/lib/widgets/critical_device_card.dart`, `lib/screens/critical_device_screen.dart`, `lib/screens/statistics_screen.dart` |
| Desktop: API client                                                     | `UI/deliverance_desktop/lib/providers/recommendation_provider.dart`                                                                             |
| Log source (scout agent)                                                | `UI/deliverance_scout/lib/utils/scout_log_collector.dart`, `scout_log_reporter.dart`                                                            |

**Library:** [ML.NET](https://dotnet.microsoft.com/apps/machinelearning-ai/ml-dotnet) `Microsoft.ML` 5.0.1, trainer [`SdcaMaximumEntropy`](https://learn.microsoft.com/dotnet/api/microsoft.ml.standardtrainerscatalog.sdcamaximumentropy).
