CREATE INDEX IF NOT EXISTS idx_test_metric_definitions_school_id ON test_metric_definitions(school_id);
CREATE INDEX IF NOT EXISTS idx_test_metric_definitions_cat_name ON test_metric_definitions(category, name);
