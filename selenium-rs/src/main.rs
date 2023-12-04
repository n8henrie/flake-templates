use std::{error, result};

use thirtyfour::common::capabilities::firefox::FirefoxPreferences;
use thirtyfour::{FirefoxCapabilities, WebDriver};

type Error = Box<dyn error::Error + Send + Sync>;
type Result<T> = result::Result<T, Error>;

#[tokio::main]
async fn main() -> Result<()> {
    let user_agent =
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:120.0) Gecko/20100101 Firefox/120.0";

    let mut prefs = FirefoxPreferences::new();
    prefs.set_user_agent(user_agent.to_string())?;

    let mut caps = FirefoxCapabilities::new();
    caps.set_preferences(prefs)?;

    let driver = WebDriver::new("http://localhost:4444", caps).await?;
    driver.goto("https://n8henrie.com").await?;

    driver.close_window().await?;
    Ok(())
}
