-- Auto delete inative buffer plugin
return {
  "chrisgrieser/nvim-early-retirement",
  -- default config time is 20 mins
  config = true,
  event = "VeryLazy",
}
