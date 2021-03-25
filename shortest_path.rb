### 利用A*算法选出最优路径
#
# require 'timeout'
# #
# timeout(1) do
#   include ShortestPath
#   model = Sketchup.active_model
#   model.start_operation '绘制线', true
#   selection = model.selection
#   face = selection.first
#
#   edges = selection.select { |e| e if e.is_a?(Sketchup::Edge) }
#
#   # 找出所有节点
#   vertices = []
#   edges.each do |edge|
#     edge.vertices.each { |v|
#       vertices << v unless vertices.include? v
#     }
#   end
#   p1 = Geom::Point3d.new(117.mm, 0, 0)
#   p2 = Geom::Point3d.new(533.mm,533.mm,0)
#   s_vertex = vertices.find {|v| v if (v.position.distance p1) < 2.mm}
#   e_vertex = vertices.find {|v| v if (v.position.distance p2) < 2.mm}
#   pts = find_path(s_vertex, e_vertex)
#   # puts "pts = #{pts}"
#   selection.clear
#   path = model.active_entities.add_group.entities.add_edges(pts)
#   selection.add(path)
#   model.commit_operation
# end
#

module ShortestPath
  class Point
    attr_accessor :parent, :point, :g, :h, :f

    def initialize(start, parent)
      self.point = start
      self.parent = parent
    end
  end

  def find_path(start_vertex, end_vertex)
    close_set = {}
    open_set = {}
    st_vertex = Point.new(start_vertex, nil)
    st_vertex.g = 0
    vertex = st_vertex
    until open_set[end_vertex]
      open_set, close_set = checked_round(vertex, end_vertex, close_set, open_set) # 检查周围元素
      vertex = get_min_f_point(open_set) # 获取f值最小的节点
    end
    vertex = open_set[end_vertex]
    path = []
    while vertex.parent
      path << vertex.point.position
      vertex = vertex.parent
    end
    path << vertex.point.position
  end

  def checked_round(vertex, end_vertex, close_set, open_set)
    # 将pos加入close列表
    close_set[vertex.point] = vertex
    # 将pos从open列表中移出
    open_set.delete(vertex.point)
    # puts vertex
    nodes(vertex.point).each do |vert|
      next if close_set[vert]

      new_vertex = Point.new(vert, vertex)
      # 计算f值
      new_vertex.g = vertex.g + g_cost(new_vertex.point.position, vertex.point.position)
      new_vertex.h = h_cost(new_vertex.point.position, end_vertex.position)
      new_vertex.f = new_vertex.g + new_vertex.h

      if open_set[new_vertex.point]
        the_vertex = open_set[new_vertex.point]
        temp_g = vertex.g + g_cost(vertex.point.position, the_vertex.point.position)
        if temp_g < the_vertex.g
          the_vertex.g = temp_g
          the_vertex.f = temp_g + the_vertex.h
          the_vertex.parent = vertex # 修改父节点为当前节点
        end
      else
        open_set[new_vertex.point] = new_vertex
      end
    end
    return open_set, close_set
  end

  def get_min_f_point(open_set)
    return nil if open_set.empty?

    min_g = open_set.values[0].g
    min_pos = open_set.values[0]
    open_set.values.each do |pos|
      if min_g > pos.g
        min_g = pos.g
        min_pos = pos
      end
    end
    min_pos
  end

  def nodes(vertex)
    vertex.edges.map do |edge| edge.other_vertex(vertex) end
  end

  # 从起点位置到当前位置消耗的实际路程
  def g_cost(point, point1)
    point.distance point1
  end

  # 从当前位置到终点的估算距离
  def h_cost(point, end_point)
    x_dis = (end_point.x - point.x).abs
    y_dis = (end_point.y - point.y).abs
    x_dis + y_dis + (Math.sqrt(2) - 2) * [x_dis, y_dis].min
  end
end
