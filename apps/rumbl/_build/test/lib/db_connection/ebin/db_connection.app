{application,db_connection,
             [{registered,[]},
              {description,"Database connection behaviour for database transactions and connection pooling\n"},
              {vsn,"0.2.4"},
              {modules,['Elixir.DBConnection','Elixir.DBConnection.App',
                        'Elixir.DBConnection.Backoff',
                        'Elixir.DBConnection.Connection',
                        'Elixir.DBConnection.Error',
                        'Elixir.DBConnection.LogEntry',
                        'Elixir.DBConnection.Ownership',
                        'Elixir.DBConnection.Ownership.Manager',
                        'Elixir.DBConnection.Ownership.Owner',
                        'Elixir.DBConnection.Ownership.OwnerSupervisor',
                        'Elixir.DBConnection.Ownership.Pool',
                        'Elixir.DBConnection.Ownership.PoolSupervisor',
                        'Elixir.DBConnection.Pool',
                        'Elixir.DBConnection.Poolboy',
                        'Elixir.DBConnection.Poolboy.Worker',
                        'Elixir.DBConnection.Query',
                        'Elixir.DBConnection.Sojourn',
                        'Elixir.DBConnection.Sojourn.Broker',
                        'Elixir.DBConnection.Sojourn.Pool',
                        'Elixir.DBConnection.Sojourn.Starter',
                        'Elixir.DBConnection.Sojourn.Supervisor',
                        'Elixir.DBConnection.Sojourn.Timeout',
                        'Elixir.DBConnection.Task',
                        'Elixir.DBConnection.Watcher']},
              {applications,[kernel,stdlib,elixir,logger,connection]},
              {mod,{'Elixir.DBConnection.App',[]}}]}.