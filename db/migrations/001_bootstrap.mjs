export const up = (pgm) => {
  pgm.createTable("app_metadata", {
    key: {
      type: "text",
      primaryKey: true,
    },
    value: {
      type: "text",
    },
    updated_at: {
      type: "timestamptz",
      notNull: true,
      default: pgm.func("current_timestamp"),
    },
  });
};

export const down = (pgm) => {
  pgm.dropTable("app_metadata");
};
