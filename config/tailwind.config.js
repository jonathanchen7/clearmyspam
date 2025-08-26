const defaultTheme = require("tailwindcss/defaultTheme");

module.exports = {
  content: [
    "./public/*.html",
    "./app/helpers/**/*.rb",
    "./app/javascript/**/*.js",
    "./app/views/**/*.{erb,haml,html,slim}",
    "./app/components/**/*.{rb,erb,haml,html,slim}",
    "./app/models/blogs/markdown_renderer.rb",
  ],
  theme: {
    extend: {
      fontSize: {
        "2xs": [".625rem", ".75rem"],
      },
      fontFamily: {
        sans: ["Inter var", ...defaultTheme.fontFamily.sans],
      },
      colors: {
        primary: "#1467c6",
        "primary-hover": "#0e4d95",
        success: "#44af69",
        danger: "#d32f2f",
        warning: "#ffe600",
        loading: "#d1d5db",
      },
    },
  },
  plugins: [
    require("@tailwindcss/forms"),
    require("@tailwindcss/typography"),
    require("@tailwindcss/container-queries"),
  ],
};
