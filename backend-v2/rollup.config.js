import { spawn } from 'child_process';
import svelte from 'rollup-plugin-svelte';
import commonjs from '@rollup/plugin-commonjs';
import terser from '@rollup/plugin-terser';
import resolve from '@rollup/plugin-node-resolve';
import css from 'rollup-plugin-css-only';
import copy from 'rollup-plugin-copy';
import postcss from 'rollup-plugin-postcss';
import { nodeResolve } from '@rollup/plugin-node-resolve';

const production = !process.env.ROLLUP_WATCH;

const App = {
  input: 'src/entries/app.js', // Tu archivo de entrada principal
  output: {
    file: 'public/dist/app.min.js',
    format: 'iife',
    sourcemap: !production
  },
  plugins: [
    // Procesamiento de CSS
    postcss({
      extract: true, // Extrae CSS a archivo separado
      minimize: production,
      plugins: [
        require('autoprefixer')() // Opcional: agrega prefijos vendor
      ]
    }),

    // Resolución de módulos
    nodeResolve({
      browser: true
    }),

    // Soporte para CommonJS
    commonjs(),

    // Minificación en producción
    production && terser(),

    // Copia archivos estáticos (opcional)
    copy({
      targets: [
        { 
					src: 'src/assets/*', 
					dest: 'public/dist/assets' 
				},
				{
          src: 'node_modules/simplemde/dist/*',
          dest: 'public/dist/'
        }
      ]
    })
  ]
};

const Login = {
	input: 'src/entries/login.js',
	output: {
		sourcemap: true,
		format: 'iife',
		name: 'login',
		file: production ? 'public/dist/login.min.js' : 'public/dist/login.js',
	},
	plugins: [
		svelte({
			compilerOptions: {
				dev: !production
			}
		}),
		css({ output: production ?  'login.min.css' : 'login.css' }),
		resolve({
			browser: true,
			dedupe: ['svelte'],
			exportConditions: ['svelte']
		}),
		commonjs(),
		production && terser()
	],
	watch: {
		clearScreen: false
	}
};

const Vendor = {
	input: 'src/entries/vendor.js',
	output: {
			sourcemap: true,
			format: 'iife',
			name: 'vendor',
			file: production ? 'public/dist/vendor.min.js' : 'public/dist/vendor.js',
	},
	plugins: [
		svelte({
			compilerOptions: {
				dev: !production
			}
		}),
	
		css({
			output: 'vendor.min.css', // siempre este nombre
			minify: true              // siempre minificado
		}),
	
		resolve({
			browser: true,
			dedupe: ['svelte'],
			exportConditions: ['svelte']
		}),
	
		commonjs(),
		production && terser(),
	
		copy({
			hook: 'writeBundle',
			targets: [
				{
					src: 'node_modules/font-awesome/fonts/*',
					dest: 'public/fonts/'
				}
			]
		})
	],
	watch: {
			clearScreen: false
	}
};

export default [Vendor, App ];