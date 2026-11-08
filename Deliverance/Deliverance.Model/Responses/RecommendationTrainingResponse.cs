namespace Deliverance.Model.Responses
{
    public class RecommendationTrainingResponse
    {
        public DateTime? TrainedAt { get; set; }
        public int? Rows { get; set; }
        public double? MicroAccuracy { get; set; }
        public double? MacroAccuracy { get; set; }
        public double? LogLoss { get; set; }
    }
}