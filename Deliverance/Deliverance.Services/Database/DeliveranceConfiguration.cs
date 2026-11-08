using Deliverance.Services.Validators;
using Microsoft.EntityFrameworkCore;


namespace Deliverance.Services.Database
{
    public partial class DeliveranceDbContext : DbContext
    {
        private void CreateConfiguration(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<User>(entity =>
            {
                entity.HasKey(e => e.UUID);
                entity.Property(e => e.UUID)
                    .HasColumnType("UNIQUEIDENTIFIER")
                    .IsRequired();
                entity.Property(u => u.Username).HasMaxLength(100);
                entity.Property(u => u.Email).HasMaxLength(256);

                entity.HasIndex(u => u.Username).IsUnique();
                entity.HasIndex(u => u.Email).IsUnique();
            });
            modelBuilder.Entity<User>()
            .HasOne(u => u.Role)
            .WithMany(r => r.Users)
            .HasForeignKey(u => u.RoleId)
            .OnDelete(DeleteBehavior.SetNull);

            modelBuilder.Entity<Conversation>()
            .HasMany(c => c.ChatBotMessages)
            .WithOne(ch => ch.Conversation)
            .HasForeignKey(ch => ch.ConversationId)
            .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<Conversation>()
            .HasOne(c => c.User)
            .WithMany(u => u.Conversations)
            .HasForeignKey(c => c.UserUUID)
            .HasPrincipalKey(u => u.UUID)
            .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<Device>()
            .HasOne(d => d.Office)
            .WithMany(o => o.Devices)
            .HasForeignKey(d => d.OfficeId)
            .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<Scout>()
            .HasOne(s => s.Device)
            .WithOne(d => d.Scout)
            .HasForeignKey<Scout>(s => s.DeviceId)
            .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<DeviceLog>()
            .HasOne(dl => dl.Scout)
            .WithMany(s => s.DeviceLogs)
            .HasForeignKey(dl => dl.ScoutId)
            .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<DeviceLog>()
            .HasIndex(dl => new { dl.ScoutId, dl.EventKey })
            .IsUnique()
            .HasFilter("[EventKey] IS NOT NULL");

            modelBuilder.Entity<DeviceLog>()
            .HasIndex(dl => new { dl.ScoutId, dl.DateLogged });

            modelBuilder.Entity<Contact>()
            .HasOne(c => c.User)
            .WithMany(u => u.Contacts)
            .HasForeignKey(c => c.UserUUID)
            .HasPrincipalKey(u => u.UUID)
            .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<Availability>()
            .HasOne(a => a.Contact)
            .WithMany(c => c.Availabilities)
            .HasForeignKey(a => a.ContactId)
            .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<Report>()
            .HasOne(r => r.User)
            .WithMany(u => u.Reports)
            .HasForeignKey(r => r.UserUUID)
            .HasPrincipalKey(u => u.UUID)
            .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<Report>(entity =>
            {
                entity.Property(r => r.Status).HasMaxLength(50);
                entity.HasIndex(r => r.Status);
            });
            modelBuilder.Entity<OfficeReport>()
                .HasIndex(or => new { or.ReportId, or.OfficeId })
                .IsUnique();
            modelBuilder.Entity<DeviceReport>()
                .HasIndex(dr => new { dr.OfficeReportId, dr.DeviceId })
                .IsUnique();
            modelBuilder.Entity<ReportOccurrence>()
                .HasIndex(ro => new { ro.ReportId, ro.OccurrenceId })
                .IsUnique();
            modelBuilder.Entity<Availability>(entity =>
            {
                entity.Property(a => a.Day).HasMaxLength(CollectionRules.DayMaxLength);
                entity.HasIndex(a => new { a.ContactId, a.Day, a.FromTime }).IsUnique();
            });

            modelBuilder.Entity<OfficeReport>()
            .HasOne(or => or.Report)
            .WithMany(r => r.OfficeReports)
            .HasForeignKey(or => or.ReportId)
            .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<OfficeReport>()
            .HasOne(or => or.Office)
            .WithMany(o => o.OfficeReports)
            .HasForeignKey(or => or.OfficeId)
            .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<DeviceReport>()
            .HasOne(dr => dr.OfficeReport)
            .WithMany(or => or.DeviceReports)
            .HasForeignKey(dr => dr.OfficeReportId)
            .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<DeviceReport>()
            .HasOne(dr => dr.Device)
            .WithMany(d => d.DeviceReports)
            .HasForeignKey(dr => dr.DeviceId)
            .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<ChatBotMessage>()
            .HasOne(m => m.User)
            .WithMany(u => u.ChatBotMessages)
            .HasForeignKey(m => m.UserUUID)
            .HasPrincipalKey(u => u.UUID)
            .OnDelete(DeleteBehavior.NoAction);

            modelBuilder.Entity<ReportOccurrence>()
            .HasOne(ro => ro.Report)
            .WithMany(r => r.ReportOccurrences)
            .HasForeignKey(ro => ro.ReportId)
            .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<ReportOccurrence>()
            .HasOne(ro => ro.Occurrence)
            .WithMany(o => o.ReportOccurrences)
            .HasForeignKey(ro => ro.OccurrenceId)
            .OnDelete(DeleteBehavior.Restrict);


            modelBuilder.Entity<RefreshTokens>()
            .HasIndex(rt => rt.Token)
            .IsUnique();

            modelBuilder.Entity<RefreshTokens>()
            .HasOne(m => m.User)
            .WithMany(u => u.RefreshToken)
            .HasForeignKey(m => m.UserUUID)
            .HasPrincipalKey(u => u.UUID)
            .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<ScoutEnrollment>()
            .HasIndex(se => se.TokenHash)
            .IsUnique();

            modelBuilder.Entity<ScoutEnrollment>()
            .HasIndex(se => se.SecretHash)
            .IsUnique()
            .HasFilter("[SecretHash] IS NOT NULL");

            modelBuilder.Entity<ScoutEnrollment>()
            .HasOne(se => se.CreatedByUser)
            .WithMany()
            .HasForeignKey(se => se.CreatedByUserUUID)
            .HasPrincipalKey(u => u.UUID)
            .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<ScoutEnrollment>()
            .HasOne(se => se.Scout)
            .WithMany()
            .HasForeignKey(se => se.ScoutId)
            .OnDelete(DeleteBehavior.SetNull);

            modelBuilder.Entity<ScoutCommand>()
            .HasOne(sc => sc.Scout)
            .WithMany(s => s.Commands)
            .HasForeignKey(sc => sc.ScoutId)
            .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<ScoutCommand>()
            .HasOne(sc => sc.ExecutionCommand)
            .WithMany()
            .HasForeignKey(sc => sc.ExecutionCommandId)
            .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<ScoutCommand>()
            .HasOne(sc => sc.CreatedByUser)
            .WithMany()
            .HasForeignKey(sc => sc.CreatedByUserUUID)
            .HasPrincipalKey(u => u.UUID)
            .OnDelete(DeleteBehavior.SetNull);

            modelBuilder.Entity<ScoutCommand>()
            .HasIndex(sc => new { sc.ScoutId, sc.CreatedAt });

            modelBuilder.Entity<ReportStatistics>()
            .HasIndex(rs => new { rs.DateReported, rs.OfficeId });

            modelBuilder.Entity<ReportStatistics>()
            .HasOne(rs => rs.User)
            .WithMany()
            .HasForeignKey(rs => rs.UserId)
            .HasPrincipalKey(u => u.UUID)
            .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<ReportStatistics>()
            .HasOne(rs => rs.Device)
            .WithMany()
            .HasForeignKey(rs => rs.DeviceId)
            .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<Office>()
            .HasOne(o => o.User)
            .WithMany()
            .HasForeignKey(o => o.UserUUID)
            .HasPrincipalKey(u => u.UUID)
            .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<Notification>()
            .HasOne(n => n.User)
            .WithMany()
            .HasForeignKey(n => n.UserUUID)
            .HasPrincipalKey(u => u.UUID)
            .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<Notification>()
            .HasIndex(n => new { n.UserUUID, n.CreatedAt });

            modelBuilder.Entity<Office>(entity =>
            {
                entity.Property(o => o.Name).HasMaxLength(100);
                entity.HasIndex(o => o.Name).IsUnique();
            });
        }
    }
}
