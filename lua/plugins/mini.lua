-- Disable closing and opening buffer animation
-- Fixed closing and opening buffer black screen flicker
return {
  {
    "echasnovski/mini.animate",
    opts = {
      open = {
        enable = false,
      },
      close = {
        enable = false,
      },
    },
  },
}
