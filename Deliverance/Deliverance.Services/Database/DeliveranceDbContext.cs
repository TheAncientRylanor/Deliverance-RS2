using Microsoft.EntityFrameworkCore;

namespace Deliverance.Services.Database
{
    public partial class DeliveranceDbContext : DbContext
    {
        public DeliveranceDbContext(DbContextOptions<DeliveranceDbContext> options) : base(options)
        {
        }

        public DbSet<Availability> Availabilities { get; set; }
        public DbSet<ChatBotMessage> ChatBotMessages { get; set; }
        public DbSet<Contact> Contacts { get; set; }
        public DbSet<ContactEmail> ContactEmails { get; set; }
        public DbSet<ContactPhoneNumber> ContactPhoneNumbers { get; set; }
        public DbSet<Device> Devices { get; set; }
        public DbSet<DeviceLog> DeviceLogs { get; set; }
        public DbSet<DeviceReport> DeviceReports { get; set; }
        public DbSet<User> Users { get; set; }
        public DbSet<Role> Roles { get; set; }
        public DbSet<Office> Offices { get; set; }
        public DbSet<OfficeReport> OfficeReports { get; set; }
        public DbSet<ReportQuestion> ReportQuestions { get; set; }
        public DbSet<Occurrence> Occurrences { get; set; }
        public DbSet<ReportOccurrence> ReportOccurrences { get; set; }
        public DbSet<Scout> Scouts { get; set; }
        public DbSet<Report> Reports { get; set; }
        public DbSet<RefreshTokens> RefreshTokens { get; set; }
        public DbSet<ReportStatistics> ReportStatistics { get; set; }
        public DbSet<ExecutionCommand> ExecutionCommands { get; set; }
        public DbSet<ScoutEnrollment> ScoutEnrollments { get; set; }
        public DbSet<ScoutCommand> ScoutCommands { get; set; }
        public DbSet<Conversation> Conversations { get; set; }
        public DbSet<Notification> Notifications { get; set; }
        protected override void ConfigureConventions(ModelConfigurationBuilder configurationBuilder)
        {
            configurationBuilder.Properties<DateTime>().HaveConversion<UtcDateTimeConverter>();
            configurationBuilder.Properties<DateTime?>().HaveConversion<UtcDateTimeConverter>();
        }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            CreateConfiguration(modelBuilder);
            CreateSeed(modelBuilder);

        }


    }
}
