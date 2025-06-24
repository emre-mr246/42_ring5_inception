#!/bin/sh

run_wp() {
    TMP_ARGS="$(mktemp /tmp/wp_args.XXXXXX)"
    printf '%s\0' "$@" > "$TMP_ARGS"
    chown www-data:www-data "$TMP_ARGS"
    gosu www-data sh -c "cd /var/www/html && HTTP_HOST='${DOMAIN_NAME}' SERVER_NAME='${DOMAIN_NAME}' xargs --null -a '$TMP_ARGS' -- wp"
    local status=$?
    rm -f "$TMP_ARGS"
    return $status
}

run_wp post create \
    --post_type=page \
    --post_content='
        <div style="text-align: center; padding: 40px; font-family: Arial, sans-serif;">
            <h1 style="color: #2c3e50; margin-bottom: 30px;">🎉 Staffogullari Family Created! 🎉</h1>
            
            <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 30px; border-radius: 15px; color: white; margin: 20px 0;">
                <h2 style="margin-top: 0;">Breaking News!</h2>
                <p style="font-size: 18px; line-height: 1.6;">
                    <strong>42 ISTANBUL</strong> - The Staffogullari Family has officially announced that new family admissions will be conducted through a comprehensive entrance examination. The testing process begins immediately for all candidates seeking family membership.
                </p>
            </div>
            
            <div style="margin-top: 50px;">
                <a href="/static" 
                   style="background: #3b82f6; 
                          color: white; 
                          padding: 12px 24px; 
                          text-decoration: none; 
                          border-radius: 8px; 
                          font-size: 16px; 
                          font-weight: 500;
                          display: inline-block;
                          transition: background-color 0.2s ease;">
                    Go to the admission test!
                </a>
            </div>
            
            <div style="margin-top: 30px; font-size: 14px; color: #7f8c8d;">
                <p>emgul.42.fr | Inception Project | 42 Istanbul</p>
            </div>
        </div>
    ' \
    --post_status=publish \
    --post_name="staffogullari-family"

page_id=$(run_wp post list --post_type=page --name="staffogullari-family" --field=ID --format=csv)
if [ -n "$page_id" ]; then
    run_wp option update show_on_front page
    run_wp option update page_on_front "$page_id"
fi

run_wp menu create "Main Menu"
run_wp menu item add-post "Main Menu" "$page_id" --title="Home"
run_wp menu location assign "Main Menu" primary || true