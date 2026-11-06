using Deliverance.Model.Enums;
using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

public class Report : IUserOwnedEntity
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    public int Id { get; set; }

    [Required]
    [MaxLength(30)]
    public string ReportName { get; set; }  = string.Empty;

    public string? Status { get; set; }

    [Required]
    public DateTime DateReported { get; set; }


    public SeverityEnum? Severity { get; set; }
    public IssueEnum? IssueType {get;set;}

    [MaxLength(255)]
    public string? Detail { get; set; }

    public Guid UserUUID { get; set; }

    public string? ReportClearedBy { get; set; }

    // Written by the admin when clearing the report.
    [MaxLength(1000)]
    public string? Comment { get; set; }

    // Local time, like the logs the recommender compares it with.
    // Null on reports cleared before this was added.
    public DateTime? DateCleared { get; set; }

    // Navigation
    [ForeignKey("UserUUID")]
    public User? User { get; set; }

    public ICollection<OfficeReport> OfficeReports { get; set; } = new List<OfficeReport>();

    public ICollection<ReportOccurance> ReportOccurances { get; set; } = new List<ReportOccurance>();

}