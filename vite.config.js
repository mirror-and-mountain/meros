import { defineConfig } from 'vite';
import tailwindcss from '@tailwindcss/vite';

export default defineConfig({
    base: '/assets/vite/build/',

    plugins: [
        tailwindcss(),
    ],
    
    build: {
        outDir: 'resources/assets/vite/build',
        emptyOutDir: true,
        manifest: true, 
        rollupOptions: {
            input: {
                app: 'resources/assets/vite/src/index.js',
            },
        },
    },
});