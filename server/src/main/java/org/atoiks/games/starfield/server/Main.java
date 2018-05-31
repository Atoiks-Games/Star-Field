/**
 * Copyright (C) 2018  Atoiks Games
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published
 * by the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

package org.atoiks.games.starfield.server;

import java.io.IOException;
import java.io.FileInputStream;

import java.util.Properties;

public class Main {

    public static final int DEFAULT_PORT = 5000;

    public static void main(String[] args) throws IOException {
        final Properties config = new Properties();
        try (final FileInputStream fis = new FileInputStream("server.properties")) {
            config.load(fis);
        }

        final int rawPort = stringToInt(config.getProperty("port"), DEFAULT_PORT);
        final int clLimit = stringToInt(config.getProperty("limit"), 8);

        final int port = rawPort < 0 ? DEFAULT_PORT : rawPort;
        System.out.println("Server starting on " + port);
        try (final Server server = new Server(port)) {
            System.out.println("Client limit is " + clLimit);
            server.start(clLimit);
            while (true) {
                Handler.list.forEach(e -> e.update(0.020f));
                try {
                    Thread.sleep(20);
                } catch (InterruptedException ex) {
                    //
                }
            }
        }
    }

    public static int stringToInt(final String str, final int defaultVal) {
        if (str == null) return defaultVal;
        try {
            return Integer.parseInt(str);
        } catch (NumberFormatException ex) {
            return defaultVal;
        }
    }
}