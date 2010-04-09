// K-3D
// Copyright (c) 1995-2010, Timothy M. Shead
//
// Contact: tshead@k-3d.com
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public
// License as published by the Free Software Foundation; either
// version 2 of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// General Public License for more details.
//
// You should have received a copy of the GNU General Public
// License along with this program; if not, write to the Free Software
// Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

/** \file
	\author Tim Shead (tshead@k-3d.com)
*/

#include <k3d-i18n-config.h>
#include <k3dsdk/application_plugin_factory.h>
#include <k3dsdk/gl.h>
#include <k3dsdk/icontext_factory_gl.h>
#include <k3dsdk/module.h>
#include <k3dsdk/ngui/application_window.h>
#include <k3dsdk/opengl/api.h>
#include <k3dsdk/opengl/offscreen_context.h>
#include <k3dsdk/plugin.h>
#include <k3dsdk/result.h>

#include <gtkmm/box.h>
#include <gtkmm/button.h>
#include <gtkmm/drawingarea.h>
#include <gtkmm/label.h>

#include <boost/assign/list_of.hpp>
#include <boost/scoped_ptr.hpp>

#include <gdk/gdkx.h>

namespace module
{

namespace osmesa
{

class test_dialog :
	public k3d::ngui::application_window,
	public k3d::iunknown
{
	typedef k3d::ngui::application_window base;

public:
	test_dialog()
	{
		Gtk::VBox* const box = new Gtk::VBox();
		add(*Gtk::manage(box));

		Gtk::Button* const offscreen_button = new Gtk::Button(_("Render offscreen"));
		offscreen_button->signal_clicked().connect(sigc::mem_fun(*this, &test_dialog::on_render_offscreen));
		box->pack_start(*Gtk::manage(offscreen_button), Gtk::PACK_SHRINK);

		Gtk::DrawingArea* const drawing_area = new Gtk::DrawingArea();
		drawing_area->signal_expose_event().connect(sigc::bind<0>(sigc::mem_fun(*this, &test_dialog::on_expose_event), drawing_area));
		box->pack_start(*Gtk::manage(drawing_area), Gtk::PACK_EXPAND_WIDGET);

		set_border_width(10);

		set_role("osmesa");
		set_title(_("OpenGL context / offscreen render testing"));
		resize(200, 200);

		show_all();
	}

	void on_render_offscreen()
	{
		try
		{
			const boost::scoped_ptr<k3d::gl::icontext_factory> factory(k3d::plugin::create<k3d::gl::icontext_factory>("OSMesaContextFactory"));
			if(!factory)
				throw std::runtime_error("Error creating context factory");

			const boost::scoped_ptr<k3d::gl::offscreen_context> context(factory->create(5, 5));
			if(!context)
				throw std::runtime_error("Error creating context");
			
			k3d::log() << debug;
			std::copy(context->buffer_begin(), context->buffer_end(), std::ostream_iterator<int>(k3d::log(), " "));
			k3d::log() << std::endl;

			context->make_current();
			context->draw().glClearColor(1.0, 0.5, 0.25, 0.125);
			context->draw().glClear(GL_COLOR_BUFFER_BIT);
			context->draw().glFlush();
			context->swap_buffers();
			
			k3d::log() << debug;
			std::copy(context->buffer_begin(), context->buffer_end(), std::ostream_iterator<int>(k3d::log(), " "));
			k3d::log() << std::endl;
		}
		catch(std::exception& e)
		{
			k3d::log() << error << e.what() << std::endl;
		}
	}

	bool on_expose_event(Gtk::DrawingArea* self, GdkEventExpose* event)
	{
		try
		{
			if(!context)
			{
				Glib::RefPtr<Gdk::Window> window = self->get_window();
				if(!window)
					throw std::runtime_error("Missing window");

				if(!window->ensure_native())
					throw std::runtime_error("Not a native window");

				const boost::scoped_ptr<k3d::gl::icontext_factory> factory(k3d::plugin::create<k3d::gl::icontext_factory>("GLXContextFactory"));
				if(!factory)
					throw std::runtime_error("Error creating context factory");

				context.reset(factory->create(reinterpret_cast<void*>(GDK_DRAWABLE_XID(window->gobj()))));
			}

			if(!context)
				throw std::runtime_error("Error creating context");
			
			Gtk::Allocation allocation = self->get_allocation();
			const int width = allocation.get_width();
			const int height = allocation.get_height();

			context->make_current();
			context->draw().glViewport(0, 0, width, height);
			context->draw().glClearColor(1.0, 0.5, 0.25, 0.125);
			context->draw().glClear(GL_COLOR_BUFFER_BIT);
			context->draw().glFlush();
			context->swap_buffers();
		}
		catch(std::exception& e)
		{
			k3d::log() << error << e.what() << std::endl;
		}

		return true;
	}

	boost::scoped_ptr<k3d::gl::context> context;

	static k3d::iplugin_factory& get_factory()
	{
		static k3d::application_plugin_factory<test_dialog> factory(
			k3d::uuid(0x5680d8e7, 0x7340433a, 0xf519bcb2, 0xc44c0d03),
			"OSMesaTestDialog",
			_("Temporary dialog for testing OpenGL contexts / offscreen rendering."),
			"NGUI Dialog",
			k3d::iplugin_factory::EXPERIMENTAL,
			boost::assign::map_list_of("ngui:component-type", "dialog")
			);

		return factory;
	}
};

/////////////////////////////////////////////////////////////////////////////
// test_dialog_factory

k3d::iplugin_factory& test_dialog_factory()
{
	return test_dialog::get_factory();
}

} // namespace osmesa

} // namespace module

