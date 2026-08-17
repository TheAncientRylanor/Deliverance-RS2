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

            modelBuilder.Entity<RefreshTokens>()
            .HasOne(m => m.User)
            .WithMany(u => u.RefreshToken)
            .HasForeignKey(m => m.UserUUID)
            .HasPrincipalKey(u => u.UUID) 
            .OnDelete(DeleteBehavior.Cascade);
        }
    }
}