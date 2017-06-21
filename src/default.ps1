Include '.\properties.ps1'

Task Default -Depends Build,DbDropAndSetup -Description "Cleans, Builds the application"

Task Clean -Description "Clean the solution" {
	Exec {
		msbuild .\angular4\bar-mgmt.sln /m /t:Clean /p:Configuration=$configuration
	}msbuild 
}

Task Build -Depends Clean -Description "Builds the solution file" {
	Exec {
		msbuild .\angular4\bar-mgmt.sln /m /t:Build /p:Configuration=$configuration
	}
}

Task dbdropandsetup -description "Drops and re-creates the database" {
	exec {
		&sqlcmd.exe -i $init_db -e -S "$dbserver" -d "master" -v databasename="$($dbname)" -v dbusername="$($dbusername)" -v dbpassword="$($dbpassword)" -t 60 -l 60 | out-null
	}
}

# Task DbMigrate -Description "Migrates the database to the latest version" {
	# Exec {
		# $migrate_cfg = [xml](Get-Content .\db-migrator\packages.config)
		# $runner=$migrate_cfg.SelectSingleNode("//packages/package[@id='FluentMigrator']")
		# $rver=$runner.GetAttribute("version")
		# $migrate_exe = ".\packages\FluentMigrator.$(rver)\tools\migrate.exe" -a ".\db-migrator\bin\$Configuration\db-migrator.dll" -c="Integrated Security=SSPI;Persist Security Info=True;Initial Catalog=$(dbname);Data Source=$(dbserver)"
	# }
# } 