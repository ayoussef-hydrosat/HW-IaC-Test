import { type CustomMessageTriggerEvent } from "aws-lambda";
import { FORGOT_PWD_BODY } from "./messages/forgotPasswordMessage";
import { WELCOME_MSG } from "./messages/welcomeMessage";

const LOGO = `
    <div style="width: 200px;">
        <svg xmlns="http://www.w3.org/2000/svg" id="Layer_2" viewBox="0 0 554.16 148.5"><defs><style>.cls-1{fill:#fc7000;}.cls-2{fill:#fcf6f2;}</style></defs><g id="Layer_1-2"><g><path class="cls-1" d="m538.48,31.54c2.82-1.87,4.91-4.62,5.97-7.88,2.57-7.91-1.77-16.43-9.68-19l-14.34-4.66-4.66,14.34c-.06.19-.12.38-.17.57-.91-3.26-2.87-6.1-5.65-8.11-6.72-4.89-16.17-3.39-21.06,3.33l-8.86,12.2,12.2,8.86c.16.12.33.23.5.34-3.38-.14-6.69.85-9.47,2.87-6.72,4.89-8.22,14.33-3.33,21.06l8.86,12.2,12.2-8.86c.16-.12.32-.24.48-.37-1.18,3.17-1.26,6.62-.2,9.89,2.57,7.91,11.09,12.25,19,9.68l14.34-4.66-4.66-14.34c-.06-.19-.13-.38-.2-.57,2.65,2.11,5.91,3.25,9.35,3.25,8.31,0,15.07-6.76,15.07-15.07v-15.08s-15.08,0-15.08,0c-.2,0-.4,0-.61.01Zm-13.54,20.29c-5.45-4.31-13.22-4.31-18.68,0,0,0,0,0,0,0h0s0,0,0,0c2.41-6.53.01-13.91-5.77-17.76h0c6.96.27,13.23-4.29,15.11-10.98,1.88,6.69,8.16,11.25,15.11,10.98-5.79,3.87-8.19,11.24-5.77,17.76Z"/><path class="cls-2" d="m269.01,90.8c-12.03,0-22.49,7.27-21.71,21.33h10.07c-.03-.28-.06-.55-.06-.86,0-6.86,4.27-11.25,11.92-11.25s11.81,4.27,11.81,9.67v2.25l-13.49,2.25c-13.27,2.14-20.47,7.54-20.47,18.11,0,7.65,5.62,16.2,18.56,16.2,7.76,0,12.82-3.82,15.52-8.43v6.75h10.01v-36.55c0-11.7-7.53-19.46-22.16-19.46Zm12.03,32.95c0,9.11-5.62,15.07-13.38,15.07-6.41,0-10.46-3.04-10.46-7.65,0-5.51,5.73-7.54,11.92-8.66l11.92-1.91v3.15Zm68.62,3.74c.49,12.94-8.1,21-19.24,21-12.94,0-20.81-7.76-20.81-20.58v-25.87h-9.9v-9.45h9.9v-16.2h10.68v16.2h27.45s0,9.45,0,9.45h-27.45v26.09c0,6.97,3.71,10.57,9.79,10.57,5.71,0,9.33-4.27,9.37-11.22h10.2Zm-283.26-15.37h-10.69c0-.14,0-.27,0-.41,0-7.31-3.38-10.91-8.77-10.91-6.52,0-11.25,5.4-11.25,15.63v30.37h-10.68v-54.21h10.68v5.51c3.04-4.39,7.76-7.2,14.17-7.2,9.85,0,16.84,6.87,16.54,21.21Zm50.71,0h-10.69c0-.14,0-.27,0-.41,0-7.31-3.38-10.91-8.77-10.91-6.52,0-11.25,5.4-11.25,15.63v30.37h-10.68v-54.21h10.68v5.51c3.04-4.39,7.76-7.2,14.17-7.2,9.85,0,16.84,6.87,16.54,21.21ZM10.69,68.08v78.74H0v-78.74h10.69Zm121.11,1.35c3.94,0,7.08,3.26,7.08,7.2s-3.15,7.2-7.08,7.2-7.2-3.15-7.2-7.2,3.15-7.2,7.2-7.2Zm5.4,23.17v54.21h-10.68v-54.21h10.68Zm36.54,38.69l16.53-63.21h11.59l16.53,63.77,15.97-63.77h10.91l-20.24,78.73h-13.05l-15.86-61.52-15.86,61.52h-13.16l-20.24-78.73h11.02l15.86,63.21Zm256.52-63.21v30.82c3.71-4.84,9.56-7.99,17.21-7.99,11.92,0,18.9,7.99,18.9,20.81v35.09h-10.69v-32.95c0-8.89-3.71-13.27-11.47-13.27-8.44,0-13.95,6.41-13.95,16.98v29.24h-10.68v-78.73h10.68Zm-20.19,59.42c-1.63,12.28-12.22,20.99-25.47,20.99-16.76,0-27.78-12.15-27.78-28.68s10.69-28.91,26.99-28.91c12.93,0,23.36,8.32,24.44,21.11h-10.75c-.76-6.71-6.97-10.88-13.69-10.88-9.67,0-16.31,7.99-16.31,17.77,0,11.47,6.75,19.34,16.87,19.34,7.12,0,13.19-4.17,15.09-10.76h10.6Z"/></g></g></svg>
    </div>
`;
export const handler = async (event: CustomMessageTriggerEvent) => {
    const isPortal = event.userPoolId === process.env.PORTAL_USER_POOL_ID;
    const isBackoffice = event.userPoolId === process.env.BACKOFFICE_USER_POOL_ID;
    const portalCallbackUrl = process.env.PORTAL_CALLBACK_URL;
    const backofficeCallbackUrl = process.env.BACKOFFICE_CALLBACK_URL;

    if (!isPortal && !isBackoffice)
        throw new Error(
            `Unknown userPoolId ${event.userPoolId} - Expecting ${process.env.PORTAL_USER_POOL_ID} or ${process.env.BACKOFFICE_USER_POOL_ID}`,
        );

    if (!portalCallbackUrl?.length) throw new Error("PORTAL_CALLBACK_URL is not defined");
    if (!backofficeCallbackUrl?.length) throw new Error("BACKOFFICE_CALLBACK_URL is not defined");

    if (event.triggerSource === "CustomMessage_ForgotPassword") {
        event.response.emailMessage = FORGOT_PWD_BODY(
            LOGO,
            event.userName,
            event.request.codeParameter,
            isPortal ? portalCallbackUrl : backofficeCallbackUrl,
        );
        event.response.emailSubject = isPortal ? "HyWater: Reset Password" : "HyWater Backoffice: Reset Password";
    } else if (event.triggerSource === "CustomMessage_AdminCreateUser") {
        event.response.emailMessage = WELCOME_MSG(
            isPortal,
            LOGO,
            event.request.usernameParameter ?? "",
            event.request.codeParameter,
            isPortal ? portalCallbackUrl : backofficeCallbackUrl,
        );
        event.response.emailSubject = isPortal ? "Welcome to HyWater" : "Welcome to HyWater Backoffice";
    }

    return event;
};
