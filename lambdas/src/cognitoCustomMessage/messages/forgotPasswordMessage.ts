export const FORGOT_PWD_BODY = (logo: string, username: string, code: string, url: string) => `
<body>
    ${logo}
    <div>
        <h2>Reset Password Request</h2>
        <div>Please click on the following link to reset your password.</div>
        <div><a href="${url}/reset-password?username=${username}&code=${code}">Reset my password</a>
    </div>
</body>
`;
