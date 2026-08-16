import defaultTheme from 'tailwindcss/defaultTheme'
import forms from '@tailwindcss/forms'
import activeAdminPlugin from '@activeadmin/activeadmin/plugin'

// Get the path to the ActiveAdmin gem
import { execSync } from 'child_process'
const activeAdminPath = execSync('bundle show activeadmin', { encoding: 'utf-8' }).trim()

export default {
  content: [
    './public/index.html',
    './app/helpers/**/*.rb',
    './app/views/**/*.{erb,haml,html,slim}',
    './app/javascript/**/*.js',
    // ActiveAdmin specific content
    `${activeAdminPath}/vendor/javascript/flowbite.js`,
    `${activeAdminPath}/plugin.js`,
    `${activeAdminPath}/app/views/**/*.{arb,erb,html,rb}`,
    './app/admin/**/*.{arb,erb,html,rb}',
    './app/views/active_admin/**/*.{arb,erb,html,rb}',
    './app/views/admin/**/*.{arb,erb,html,rb}',
    './app/views/layouts/active_admin*.{erb,html}',
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: ['Inter var', ...defaultTheme.fontFamily.sans],
      },
      // Grille typographique normalisée (auth + plateforme)
      fontSize: {
        'body': ['1rem', { lineHeight: '1.5' }],      // 16px — champs, corps
        'label': ['0.875rem', { lineHeight: '1.25' }], // 14px — labels, liens secondaires
        'caption': ['0.75rem', { lineHeight: '1.25' }], // 12px — hints, légendes
        'title': ['1.5rem', { lineHeight: '1.3' }],  // 24px — titres de page auth
      },
    },
  },
  plugins: [
    forms,
    activeAdminPlugin,
  ],
  darkMode: 'selector',
}
