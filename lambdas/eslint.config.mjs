import typescriptPlugin from "@typescript-eslint/eslint-plugin";
import typescriptParser from "@typescript-eslint/parser";
import pluginPrettier from "eslint-plugin-prettier";

export default [
  {
    files: ["**/*.ts"],
    languageOptions: {
      parser: typescriptParser,
      ecmaVersion: 2021,
      sourceType: "module",
      parserOptions: {
        project: ["./tsconfig.json"],
      },
      globals: {
        console: true,
        process: true,
        Buffer: true,
        setTimeout: true,
        clearTimeout: true,
        setInterval: true,
        clearInterval: true,
        require: true,
        module: true,
        exports: true,
        __dirname: true,
        __filename: true,
        test: true,
        expect: true,
        describe: true,
        beforeEach: true,
        afterEach: true,
      },
    },
    plugins: {
      "@typescript-eslint": typescriptPlugin,
      prettier: pluginPrettier,
    },
    rules: {
      "no-new": "off",
      "no-console": "error",

      "@typescript-eslint/no-useless-constructor": "off",
      "@typescript-eslint/explicit-function-return-type": "off",
      "@typescript-eslint/no-non-null-assertion": "off",
      "@typescript-eslint/no-floating-promises": "off",
      "@typescript-eslint/no-misused-promises": "off",
      "@typescript-eslint/no-extraneous-class": "off",
      "@typescript-eslint/strict-boolean-expressions": "off",
      "@typescript-eslint/ban-ts-comment": "off",
      "@typescript-eslint/prefer-ts-expect-error": "off",
      "@typescript-eslint/consistent-type-assertions": "off",

      "prettier/prettier": "warn",
    },
  },
];
