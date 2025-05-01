const defaultTheme = require("tailwindcss/defaultTheme");

module.exports = {
  content: [
    "./app/views/**/*.{html,erb,haml,slim}", // all your view templates
    "./app/helpers/**/*.rb", // any `class_name` in helpers
    "./app/javascript/**/*.js", // JS-driven markup (Stimulus, etc.)
    "./app/components/**/*.{rb,html.erb}", // if you’re using ViewComponents
    "./public/**/*.html", // standalone HTML (if any)
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: ["Poppins", ...defaultTheme.fontFamily.sans],
      },
      colors: {
        blue: "#224BB4",
        black: "#242424",
      },
    },
  },
  plugins: [
    require("@tailwindcss/forms"),
    require("@tailwindcss/aspect-ratio"),
    require("@tailwindcss/typography"),
    require("@tailwindcss/container-queries"),
  ],
};
