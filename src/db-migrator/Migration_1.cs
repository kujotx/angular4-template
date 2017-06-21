using FluentMigrator;

namespace db_migrator
{
    /// <summary>
    /// First migration for creating the database
    /// </summary>
    [Migration(1)]
    public class Migration_1 : ForwardOnlyMigration
    {
        public override void Up()
        {
            Create.Table("Bar")
                .WithColumn("BarId").AsGuid().PrimaryKey()
                .WithColumn("Name").AsString(255);
        }
    }
}
