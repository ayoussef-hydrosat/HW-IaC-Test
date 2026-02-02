const WELCOME_MSG_PORTAL = (logo: string, username: string, code: string, url: string) => `
<body>
    ${logo}
    <div>
        <p>Dear HyWater Customer,</p>
        <p>
            We are pleased to inform that the HyWater portal is ready for you. To login, visit <a href="${url}">${url}</a> <br /><br />Your username is ${username} and password is ${code}
        </p>
        <p>
            Best Regards,<br />
            <a href="${url}">Hydrosat Team</a>
        </p>
    </div>
</body>
`;

const WELCOME_MSG_BACKOFFICE = (logo: string, username: string, code: string, url: string) => `
<body>
    ${logo}
    <div>
        <p>Dear HyWater Admin,</p>
        <p>
            You have been invited to the HyWater Backoffice. To login, visit <a href="${url}">${url}</a> <br /><br />Your username is ${username} and password is ${code}
        </p>
        <p>
            Best Regards,<br />
            <a href="${url}">Hydrosat Team</a>
        </p>
    </div>
</body>
`;

export const WELCOME_MSG = (isPortal: boolean, logo: string, username: string, code: string, url: string) => {
    return isPortal ? WELCOME_MSG_PORTAL(logo, username, code, url) : WELCOME_MSG_BACKOFFICE(logo, username, code, url);
};
