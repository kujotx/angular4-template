using FluentMigrator;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace db_migrator
{
    /// <summary>
    /// First migration for creating the database
    /// </summary>
    [Migration(1)]
    public class Migration_1 : FluentMigrator.ForwardOnlyMigration
    {
        public override void Up()
        {
            throw new NotImplementedException();
        }
    }
}
