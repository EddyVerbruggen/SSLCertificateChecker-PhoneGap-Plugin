package nl.xservices.plugins;

import org.apache.cordova.api.CallbackContext;
import org.apache.cordova.api.CordovaPlugin;
import org.json.JSONArray;
import org.json.JSONException;

import javax.net.ssl.HttpsURLConnection;
import javax.security.cert.CertificateException;
import java.io.IOException;
import java.net.URL;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.cert.Certificate;
import java.security.cert.CertificateEncodingException;

public class SSLCertificateChecker extends CordovaPlugin {

  private static final String ACTION_CHECK_EVENT = "check";
  private static char[] HEX_CHARS = {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F'};

  @Override
  public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
    try {
      if (ACTION_CHECK_EVENT.equals(action)) {
        final String serverURL = args.getString(0);
        final String allowedFingerprint = args.getString(1);
        final String allowedFingerprintAlt = args.getString(2);

        final String serverCertFingerprint = getFingerprint(serverURL);

        if (allowedFingerprint.equalsIgnoreCase(serverCertFingerprint) || allowedFingerprintAlt.equalsIgnoreCase(serverCertFingerprint)) {
          callbackContext.success("CONNECTION_SECURE");
        } else {
          callbackContext.success("CONNECTION_NOT_SECURE");
        }
        return true;
      } else {
        callbackContext.error("sslCertificateChecker." + action + " is not a supported function. Did you mean '" + ACTION_CHECK_EVENT + "'?");
        return false;
      }
    } catch (Exception e) {
      callbackContext.error("CONNECTION_FAILED");
      return false;
    }
  }

  private String getFingerprint(String httpsURL) throws IOException, NoSuchAlgorithmException, CertificateException, CertificateEncodingException {
    final HttpsURLConnection con = (HttpsURLConnection) new URL(httpsURL).openConnection();
    con.connect();
    final Certificate cert = con.getServerCertificates()[0];
    final MessageDigest md = MessageDigest.getInstance("SHA1");
    md.update(cert.getEncoded());
    return dumpHex(md.digest());
  }

  private static String dumpHex(byte[] data) {
    final int n = data.length;
    final StringBuilder sb = new StringBuilder(n * 3 - 1);
    for (int i = 0; i < n; i++) {
      if (i > 0) {
        sb.append(' ');
      }
      sb.append(HEX_CHARS[(data[i] >> 4) & 0x0F]);
      sb.append(HEX_CHARS[data[i] & 0x0F]);
    }
    return sb.toString();
  }
}