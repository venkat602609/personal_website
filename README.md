# Personal Website

Minimal personal website with a mortgage amortization calculator.

## Local preview

Run a local server from the project root:

```bash
python3 -m http.server 8000
```

Then open `http://127.0.0.1:8000`.

## Publish to GitHub Pages

1. Create a new GitHub repository.
2. Add the remote:

```bash
git remote add origin <your-repo-url>
```

3. Commit and push:

```bash
git add .
git commit -m "Initial personal website"
git push -u origin main
```

4. In GitHub, open:
   `Settings` -> `Pages` -> `Build and deployment`
5. Set `Source` to `GitHub Actions`.
6. The included workflow will deploy the site automatically.

After deployment, your site will be available at:

`https://<your-github-username>.github.io/<repository-name>/`

If you later rename this into a user site repo called
`<your-github-username>.github.io`, it will publish at the root domain:

`https://<your-github-username>.github.io/`
