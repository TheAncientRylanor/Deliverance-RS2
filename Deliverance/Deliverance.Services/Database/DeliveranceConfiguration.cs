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
            .OnDelete(DeleteBehavior.SetNull);

            modelBuilder.Entity<Report>(entity =>
            {
                entity.Property(r => r.Status).HasMaxLength(50);
                entity.HasIndex(r => r.Status);
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
            .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<ChatBotMessage>()
            .HasOne(m => m.User)
            .WithMany(u => u.ChatBotMessages)
            .HasForeignKey(m => m.UserUUID)
            .HasPrincipalKey(u => u.UUID)
            .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<ReportOccurance>()
            .HasOne(ro => ro.Report)
            .WithMany(r => r.ReportOccurances)
            .HasForeignKey(ro => ro.ReportId)
            .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<ReportOccurance>()
            .HasOne(ro => ro.Occurance)
            .WithMany(o => o.ReportOccurances)
            .HasForeignKey(ro => ro.OccuranceId)
            .OnDelete(DeleteBehavior.Cascade);


            modelBuilder.Entity<RefreshTokens>()
            .HasIndex(rt => rt.Token)
            .IsUnique();

            modelBuilder.Entity<RefreshTokens>()
            .HasOne(m => m.User)
            .WithMany(u => u.RefreshToken)
            .HasForeignKey(m => m.UserUUID)
            .HasPrincipalKey(u => u.UUID)
            .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<ReportStatistics>()
            .HasIndex(rs => new { rs.DateReported, rs.OfficeId });

            modelBuilder.Entity<ReportStatistics>()
            .HasOne(rs => rs.User)
            .WithMany()
            .HasForeignKey(rs => rs.UserId)
            .HasPrincipalKey(u => u.UUID)
            .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<Office>(entity =>
            {
                // nvarchar(max) can't be indexed, so the name needs a length.
                entity.Property(o => o.Name).HasMaxLength(100);
                entity.HasIndex(o => o.Name).IsUnique();
            });
        }
    }
}